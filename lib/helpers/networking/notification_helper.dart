import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../view/global/chat/screen/admin_chat_screen.dart';
import '../../view/global/chat/screen/chat_screen.dart';
import '../../view/layout/delegate_bottom_nav_bar.dart/screen/delegate_bottom_nav_bar_screen.dart';
import '../../view/layout/notification/model/notfication_from_firebase_model.dart';
import '../../view/layout/order/screen/order_details_delegate_screen.dart';
import '../../view/layout/wallet/screen/wallet_screen.dart';
import '../routes/app_routers_import.dart';
import '../utils/navigator_methods.dart';

import 'sound_notification.dart';
export 'sound_notification.dart';

class NotificationHelper {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (notificationResponse) {
        _handleNotificationTap(notificationResponse);
      },
      // onDidReceiveBackgroundNotificationResponse: tapNotification,
    );
  }

  Future<void> display(RemoteMessage message) async {
    // Sound is independent of whether a visual notification can be displayed.
    final data = message.data;
    if (data['notification_sound'] == 'long' ||
        incomingOrderSoundKey(data) != null) {
      await SoundNotification.instance.playSound(
        key:
            incomingOrderSoundKey(data) ??
            data['event_id']?.toString() ??
            message.messageId,
      );
    }
    try {
      var android = const AndroidNotificationDetails(
        'go_partner_foreground_v2',
        'GO Partner in-app notifications',
        importance: Importance.high,
        priority: Priority.high,
        channelDescription: 'GO Partner alerts while the app is open',
        colorized: true,
        color: Color(0xff469D8F),
        playSound: false, // تعطيل الصوت الافتراضي
      );
      var iOS = const DarwinNotificationDetails(presentSound: false);
      var platform = NotificationDetails(android: android, iOS: iOS);
      await _flutterLocalNotificationsPlugin.show(
        0,
        message.notification?.title ?? data['title']?.toString(),
        message.notification?.body ?? data['text']?.toString(),
        platform,
        payload: json.encode(message.data),
      );
    } catch (e) {
      log(e.toString());
    }
  }
}

void _handleNotificationTap(NotificationResponse notificationResponse) {
  final String? payload = notificationResponse.payload;
  if (payload != null) {
    log('Notification tapped with payload: $payload');

    final data = json.decode(payload);
    _onNotificationTapedDelegate(RemoteMessage(data: data));
  }
}

void _navigateToScreenIfNotCurrent(String routeName, {Object? arguments}) {
  NavigatorMethods.pushNamed(
    AppRouters.navigatorKey.currentContext!,
    routeName,
    arguments: arguments,
  );
  log('Navigating to From Helper $routeName');
}

void _onNotificationTapedDelegate(RemoteMessage message) {
  SoundNotification.instance.stopSound();

  final msg = json.encode(message.data);
  var body = json.decode(msg);
  final data = NotificationFromFirebaseMode.fromJson(body);

  switch (data.notificationType.toString()) {
    case '1':
      _navigateToScreenIfNotCurrent(
        OrderDetailsDelegateScreen.routeName,
        arguments: OrderDetailsDelegateScreenArgs(
          fromHome: false,
          orderId: int.parse(data.orderId.toString()),
        ),
      );
      break;
    case '3':
      _navigateToScreenIfNotCurrent(WalletScreen.routeName);
      break;
    case '8':
      _navigateToScreenIfNotCurrent(
        ChatScreen.routeName,
        arguments: ChatScreenArgs(
          senderDeviceToken: data.receiverDeviceToken.toString(),
          accountType: data.accountType.toString(),
          isVendor: false,
          vendorDeviceToken: data.receiverDeviceToken.toString(),
          receiverDeviceToken: data.senderDeviceToken.toString(),
          senderName: data.receiverName.toString(),
          receiverName: data.senderName.toString(),
          orderId: data.orderId.toString(),
        ),
      );
      break;
    case '10':
      _navigateToScreenIfNotCurrent(
        AdminChatScreen.routeName,
        arguments: AdminChatScreenArgs(
          senderId: data.receiverId.toString(),
          receiverId: data.senderId.toString(),
          receiverDeviceToken: data.senderDeviceToken.toString(),
          senderDeviceToken: data.receiverDeviceToken.toString(),
          senderName: data.receiverName.toString(),
          receiverName: data.senderName.toString(),
          accountType: data.accountType.toString(),
          isToVendor: true,
          vendorDeviceToken: data.receiverDeviceToken.toString(),
        ),
      );
      break;
    default:
      _navigateToScreenIfNotCurrent(DelegateBottomNavBarScreen.routeName);
  }
}
