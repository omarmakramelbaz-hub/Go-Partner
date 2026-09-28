import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'app.dart';
import 'firebase_options.dart';
import 'helpers/networking/http_overrides_stub.dart'
    if (dart.library.io) 'helpers/networking/http_overrides_io.dart';
import 'helpers/networking/notification_helper.dart';
import 'helpers/theme/app_theme_controller.dart';
import 'helpers/theme/theme_enum.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only keep local, non-network startup work before the first Flutter frame.
  // Firebase / messaging initialization is intentionally moved after runApp
  // so a plugin/network issue can never leave the delegate app stuck on the
  // native orange launch screen.
  await EasyLocalization.ensureInitialized();
  await initLocalServices();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'i18n',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      saveLocale: true,
      child: ChangeNotifierProvider(
        create: (context) => AppThemeController()..initial(),
        child: const MyApp(),
      ),
    ),
  );

  if (!kIsWeb) {
    unawaited(initNativeServices());
  }
}

Future<void> initLocalServices() async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ThemeEnumAdapter());
  }
  await Hive.openBox('app');

  timeago.setLocaleMessages('en', timeago.EnMessages());
  timeago.setLocaleMessages('en_short', timeago.EnShortMessages());
  timeago.setLocaleMessages('ar', timeago.ArMessages());
  timeago.setLocaleMessages('ar_short', timeago.ArShortMessages());

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    configureHttpOverrides();
  }
}

Future<void> initNativeServices() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 8));

    FirebaseMessaging.onBackgroundMessage(onAppBackground);
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: false, badge: false, sound: false,
    );
    await NotificationHelper().initialize();
  } catch (error, stackTrace) {
    // Startup must remain usable even if Firebase is temporarily unavailable.
    debugPrint('Native Firebase startup skipped: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

@pragma('vm:entry-point')
Future<void> onAppBackground(RemoteMessage message) async {
  // FCM notification payloads are already presented by the operating system.
  // A second player in Android's background isolate cannot be stopped by the
  // foreground order button, so never start duplicate media playback here.
  if (message.notification != null) return;
  final helper = NotificationHelper();
  await helper.initialize();
  await helper.display(message);
  await Future<void>.delayed(SoundNotification.duration);
  await SoundNotification.instance.stopSound();
}
