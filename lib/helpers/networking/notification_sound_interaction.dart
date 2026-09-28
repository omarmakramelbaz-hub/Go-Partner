import 'dart:async';

import 'package:flutter/material.dart';

import 'sound_notification.dart';

/// Pointer events reach this listener even when a child button wins the gesture.
class NotificationSoundInteraction extends StatelessWidget {
  const NotificationSoundInteraction({
    super.key,
    required this.child,
    this.sound,
  });
  final Widget child;
  final SoundNotification? sound;

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) =>
        unawaited((sound ?? SoundNotification.instance).stopSound()),
    child: child,
  );
}
