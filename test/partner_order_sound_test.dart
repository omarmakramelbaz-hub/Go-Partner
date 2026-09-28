import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_partner/helpers/networking/notification_sound_interaction.dart';
import 'package:go_partner/helpers/networking/sound_notification.dart';
import 'package:go_partner/view/layout/order/controller/partner_orders_controller.dart';
import 'package:go_partner/view/layout/order/model/partner_order.dart';
import '../lib/go_services/partner_service_board.dart';

import 'support/partner_orders_fixtures.dart';
import 'go_services_test.dart' as services;

class FakeAudio implements NotificationAudio {
  int plays = 0;
  int stops = 0;
  bool playing = false;
  bool fail = false;
  Completer<void>? preparing;
  @override
  Future<void> prepare() async {
    if (preparing != null) await preparing!.future;
    if (fail) throw StateError('Audio permission unavailable');
  }

  @override
  Future<void> play() async {
    plays++;
    playing = true;
  }

  @override
  Future<void> stop() async {
    stops++;
    playing = false;
  }
}

void main() {
  test('bundled recording is exactly one second of PCM audio', () {
    final bytes = File('assets/${SoundNotification.asset}').readAsBytesSync();
    final data = ByteData.sublistView(bytes);
    expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
    int? bytesPerSecond;
    int? audioSize;
    for (var offset = 12; offset + 8 <= bytes.length;) {
      final chunk = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final size = data.getUint32(offset + 4, Endian.little);
      if (chunk == 'fmt ')
        bytesPerSecond = data.getUint32(offset + 16, Endian.little);
      if (chunk == 'data') audioSize = size;
      offset += 8 + size + (size % 2);
    }
    expect(bytesPerSecond, isNotNull);
    expect(audioSize, bytesPerSecond);
  });

  testWidgets('a new order rings once for one second without a loop', (
    tester,
  ) async {
    final player = FakeAudio();
    final sound = SoundNotification(audio: player);
    unawaited(sound.playLongSound(key: 'delivery:1'));
    await tester.pump();
    expect(player.plays, 1);
    await tester.pump(const Duration(milliseconds: 999));
    expect(player.playing, isTrue);
    await tester.pump(const Duration(milliseconds: 1));
    expect(player.playing, isFalse);
    await tester.pump(const Duration(minutes: 2));
    expect(player.plays, 1);
  });

  testWidgets('duplicate push and polling do not extend or restart the sound', (
    tester,
  ) async {
    final player = FakeAudio();
    final sound = SoundNotification(audio: player);
    unawaited(sound.playSound(key: 'delivery:1'));
    await tester.pump(const Duration(milliseconds: 600));
    unawaited(sound.playSound(key: 'delivery:1'));
    await tester.pump(const Duration(milliseconds: 400));
    // The timer starts after platform preparation in the first pump.
    await tester.pump(const Duration(milliseconds: 600));
    expect(player.playing, isFalse);
    unawaited(sound.playSound(key: 'delivery:1'));
    await tester.pump();
    expect(player.plays, 1);
  });

  testWidgets(
    'action immediately stops audio and late duplicate stays silent',
    (tester) async {
      final player = FakeAudio();
      final sound = SoundNotification(audio: player);
      unawaited(sound.playSound(key: 'service:1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      sound.acknowledge('service:1');
      await tester.pump();
      expect(player.playing, isFalse);
      unawaited(sound.playSound(key: 'service:1'));
      await tester.pump();
      expect(player.plays, 1);
      await tester.pump(const Duration(seconds: 2));
      expect(player.stops, 1);
    },
  );

  testWidgets('action during asset loading prevents delayed playback', (
    tester,
  ) async {
    final player = FakeAudio()..preparing = Completer<void>();
    final sound = SoundNotification(audio: player);
    unawaited(sound.playSound(key: 'job:1'));
    await tester.pump();
    sound.acknowledge('job:1');
    player.preparing!.complete();
    await tester.pump();
    expect(player.plays, 0);
    expect(player.playing, isFalse);
  });

  testWidgets('old timers cannot stop the next order early', (tester) async {
    final player = FakeAudio();
    final sound = SoundNotification(audio: player);
    unawaited(sound.playSound(key: 'delivery:1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    unawaited(sound.playSound(key: 'delivery:2'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(player.playing, isTrue);
    await tester.pump(const Duration(milliseconds: 750));
    expect(player.playing, isFalse);
    expect(player.plays, 2);
  });

  testWidgets('child order button stops the sound on pointer down', (
    tester,
  ) async {
    final player = FakeAudio();
    final sound = SoundNotification(audio: player);
    var actions = 0;
    await tester.pumpWidget(
      NotificationSoundInteraction(
        sound: sound,
        child: MaterialApp(
          home: Scaffold(
            body: FilledButton(
              onPressed: () => actions++,
              child: const Text('Accept'),
            ),
          ),
        ),
      ),
    );
    unawaited(sound.playSound());
    await tester.pump();
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Accept')),
    );
    await tester.pump();
    expect(player.playing, isFalse);
    expect(actions, 0);
    await gesture.up();
    await tester.pump();
    expect(actions, 1);
  });

  testWidgets('audio failure does not escape and later notifications recover', (
    tester,
  ) async {
    final player = FakeAudio()..fail = true;
    final sound = SoundNotification(audio: player);
    unawaited(sound.playSound(key: 'delivery:1'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    player.fail = false;
    unawaited(sound.playSound(key: 'delivery:2'));
    await tester.pump();
    expect(player.plays, 1);
    unawaited(sound.resetSession());
    await tester.pump();
    unawaited(sound.playSound(key: 'delivery:2'));
    await tester.pump();
    expect(player.plays, 2);
    unawaited(sound.stopSound());
    await tester.pump();
  });

  test('push payload variants match inbox and Pusher identities', () {
    for (final field in ['notificationType', 'notification_type']) {
      expect(
        incomingOrderSoundKey({
          field: '1',
          'order_id': 8,
          'notification_sound': 'long',
        }),
        'delivery:8',
      );
      expect(
        incomingOrderSoundKey({field: 7, 'partner_service_request_id': '8'}),
        'service:8',
      );
      expect(
        incomingOrderSoundKey({
          field: 7,
          'go_service_job_id': 8,
          'event_id': 'job:8:invited:user:9',
        }),
        'job:8',
      );
    }
    expect(
      incomingOrderSoundKey({
        'notification_type': 7,
        'go_service_job_id': 8,
        'event_id': 'job:8:completed:user:9',
      }),
      isNull,
    );
  });

  for (final professional in [true, false]) {
    testWidgets(
      'new ${professional ? 'service' : 'courier'} polling results alert only once',
      (tester) async {
        final repository = MemoryOrdersRepository();
        final keys = <String>[];
        final controller = PartnerOrdersController(
          isProfessional: professional,
          repository: repository,
          onIncomingOrder: keys.add,
        );
        controller.startLiveUpdates();
        await tester.pump();
        repository.items.add(
          professional
              ? serviceOrder(1, 'pending')
              : deliveryOrder(1, 'pending'),
        );
        await tester.pump(PartnerOrdersController.liveRefreshInterval);
        expect(keys, [professional ? 'service:1' : 'delivery:1']);
        await tester.pump(PartnerOrdersController.liveRefreshInterval);
        expect(keys.length, 1);
        controller.dispose();
      },
    );
  }

  for (final action in [
    PartnerOrderAction.accept,
    PartnerOrderAction.decline,
  ]) {
    testWidgets('${action.name} silences before slow server response', (
      tester,
    ) async {
      final player = FakeAudio();
      final sound = SoundNotification(audio: player);
      final repository = MemoryOrdersRepository()
        ..items.add(serviceOrder(1, 'pending'))
        ..writeGate = Completer<void>();
      final controller = PartnerOrdersController(
        isProfessional: true,
        repository: repository,
        onOrderAction: sound.acknowledge,
      );
      unawaited(controller.refresh());
      await tester.pump();
      unawaited(sound.playSound(key: 'service:1'));
      await tester.pump();
      final result = controller.act(controller.incoming.single, action);
      await tester.pump();
      expect(player.playing, isFalse);
      expect(repository.writeGate!.isCompleted, isFalse);
      repository.writeGate!.complete();
      await tester.pump();
      expect(await result, isTrue);
      controller.dispose();
    });
  }

  testWidgets(
    'professional quotation board sounds only for newly invited jobs',
    (tester) async {
      final jobs = <Map<String, dynamic>>[];
      final keys = <String>[];
      final client = services.api(
        services.MemoryAdapter(
          (r) => r.path.endsWith('capabilities')
              ? services.reply({
                  'schema_ready': true,
                  'version': 1,
                  'enabled': true,
                })
              : services.reply({'items': jobs, 'balance': '100.00'}),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PartnerServiceBoard(
                ar: false,
                api: client,
                onIncomingOrder: keys.add,
                legacyBuilder: (_) => const SizedBox(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      jobs.add(services.exampleJob());
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();
      expect(keys, ['job:7']);
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();
      expect(keys.length, 1);
      await tester.pumpWidget(const SizedBox());
      client.close();
    },
  );
}
