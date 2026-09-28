import 'dart:async';
import 'dart:collection';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

abstract class NotificationAudio {
  Future<void> prepare();
  Future<void> play();
  Future<void> stop();
}

class _NotificationAudio implements NotificationAudio {
  AudioPlayer? _player;
  @override
  Future<void> prepare() async {
    final player = _player ??= AudioPlayer();
    await player.stop();
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(AssetSource(SoundNotification.asset));
  }

  @override
  Future<void> play() => _player!.resume();

  @override
  Future<void> stop() async {
    await _player?.stop();
  }
}

/// One bounded sound shared by push, live events and the authenticated inbox.
class SoundNotification {
  SoundNotification({required NotificationAudio audio}) : _audio = audio;
  static final instance = SoundNotification(audio: _NotificationAudio());
  static const duration = Duration(seconds: 1);
  // The file itself is one second too: suspended/throttled Dart timers cannot
  // leave a longer recording or a loop playing in the background.
  static const asset = 'sound/order_alert.wav';
  final NotificationAudio _audio;
  final LinkedHashSet<String> _seen = LinkedHashSet();
  Future<void> _pending = Future<void>.value();
  Timer? _timer;
  int _revision = 0;
  bool _active = false;

  void _remember(String key) {
    _seen.add(key);
    while (_seen.length > 256) {
      _seen.remove(_seen.first);
    }
  }

  Future<void> _enqueue(Future<void> Function() action) {
    _pending = _pending.then((_) async {
      try {
        await action();
      } catch (error) {
        // Permission, silent mode, browser autoplay or an audio plugin failure
        // must never break receiving or acting on an order.
        debugPrint('Notification audio unavailable: $error');
      }
    });
    return _pending;
  }

  Future<void> playSound({String? key}) {
    if (key != null && _seen.contains(key)) return Future<void>.value();
    if (key != null) _remember(key);
    final revision = ++_revision;
    _active = true;
    _timer?.cancel();
    return _enqueue(() async {
      if (revision != _revision) return;
      await _audio.prepare();
      // An action may have happened while the platform loaded the asset.
      if (revision != _revision) return;
      await _audio.play();
      if (revision != _revision) {
        await _audio.stop();
        return;
      }
      _timer = Timer(duration, () {
        if (revision == _revision) unawaited(stopSound());
      });
    });
  }

  // Keep older order widgets compatible without retaining a looping path.
  Future<void> playLongSound({String? key}) => playSound(key: key);

  Future<void> stopSound() {
    ++_revision;
    _timer?.cancel();
    _timer = null;
    if (!_active) return _pending;
    _active = false;
    return _enqueue(_audio.stop);
  }

  void acknowledge(String key) {
    _remember(key);
    unawaited(stopSound());
  }

  Future<void> resetSession() {
    _seen.clear();
    return stopSound();
  }
}

/// Normalize both payload spellings and match polling/Pusher order identities.
String? incomingOrderSoundKey(Map<String, dynamic> data) {
  final type = (data['notification_type'] ?? data['notificationType'])
      ?.toString();
  String? id(String field) {
    final value = data[field]?.toString();
    return value == null || value.isEmpty ? null : value;
  }

  if (type == '1' && data['notification_sound'] == 'long') {
    final order = id('order_id');
    return order == null ? null : 'delivery:$order';
  }
  if (type == '7') {
    final request = id('partner_service_request_id');
    if (request != null) return 'service:$request';
    final job = id('go_service_job_id');
    if (job != null && (id('event_id')?.contains(':invited:') ?? false)) {
      return 'job:$job';
    }
  }
  return null;
}
