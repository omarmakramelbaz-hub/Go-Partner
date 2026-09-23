import 'dart:convert';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../global/widget/no_notification_widget.dart';
import '../controller/notifications_delegate_Controller.dart';
import '../model/notifications_model.dart';
import '../widget/notification_delegate_widget.dart';

class NotificationsDelegateScreen extends StatefulWidget {
  const NotificationsDelegateScreen({super.key});

  @override
  State<NotificationsDelegateScreen> createState() => _NotificationsDelegateScreenState();
}

class _NotificationsDelegateScreenState extends State<NotificationsDelegateScreen> {
  late PusherController _pusherController;

  @override
  void initState() {
    super.initState();
    _pusherController = context.read<PusherController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<NotificationsDelegateController>();
      controller.initialNotifications();
      controller.getNotifications().then((_) {
        if (mounted) setState(() {});
      });
    });
    _pusherController.addEventListener('notification.updated', _handleDelegateUpdated);
  }

  void _handleDelegateUpdated(PusherEvent event) {
    try {
      final jsonData = jsonDecode(event.data) as Map<String, dynamic>;
      log('Notification updated: $jsonData');
      if (!mounted) return;
      final notification = NotificationsModel.fromJson(jsonData);
      context.read<NotificationsDelegateController>().addNotificationToTop(notification);
    } catch (e, stackTrace) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    _pusherController.removeEventListener('notification.updated', _handleDelegateUpdated);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF171A1F);
    const softText = Color(0xff7D8490);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(context, title: Text(AppLocaleKey.notifications.tr())),
      body: Consumer<NotificationsDelegateController>(
        builder: (context, controller, _) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xffFF8A08), Color(0xffFF6500)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xffFD7201).withOpacity(.20),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 25),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocaleKey.notifications.tr(),
                            style: const TextStyle(color: navy, fontSize: 25, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            context.locale.languageCode == 'ar'
                                ? 'كل جديد عن طلباتك وحسابك'
                                : 'Updates about your orders and account',
                            style: const TextStyle(color: softText, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    if (controller.notifications.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xffFFF0E3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          controller.notifications.length.toString(),
                          style: const TextStyle(color: Color(0xffFD7201), fontSize: 13, fontWeight: FontWeight.w900),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                ApiResponseWidget(
                  apiResponse: controller.notificationsResponse,
                  onReload: controller.getNotifications,
                  isEmpty: controller.notifications.isEmpty,
                  emptyWidget: const NoNotificationWidget(),
                  child: Expanded(
                    child: RefreshIndicator(
                      color: const Color(0xffFD7201),
                      onRefresh: controller.getNotifications,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 110),
                        itemCount: controller.notifications.length,
                        itemBuilder: (context, index) {
                          final notification = controller.notifications[index];
                          return NotificationDelegateWidget(
                            notificationType: notification.data?.notificationData?.notificationType ?? 0,
                            notification: notification,
                            orderId: notification.data?.notificationData?.orderId ?? 0,
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
