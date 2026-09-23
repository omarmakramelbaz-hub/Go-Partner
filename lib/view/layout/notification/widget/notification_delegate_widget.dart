import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/networking/notification_helper.dart';
import '../../../../helpers/utils/date_methods.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../order/screen/order_details_delegate_screen.dart';
import '../../wallet/screen/wallet_screen.dart';
import '../model/notifications_model.dart';

class NotificationDelegateWidget extends StatelessWidget {
  final NotificationsModel notification;
  final int orderId;
  final int notificationType;

  const NotificationDelegateWidget({
    super.key,
    required this.notification,
    required this.orderId,
    required this.notificationType,
  });

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF171A1F);
    const softText = Color(0xff7D8490);
    const orange = Color(0xffFD7201);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          SoundNotification.instance.stopSound();
          log('notification tapped');
          if (notificationType == 1) {
            NavigatorMethods.pushNamed(
              context,
              OrderDetailsDelegateScreen.routeName,
              arguments: OrderDetailsDelegateScreenArgs(fromHome: false, orderId: orderId),
            );
          } else if (notificationType == 3) {
            NavigatorMethods.pushNamed(context, WalletScreen.routeName);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xffECEEF1)),
            boxShadow: [
              BoxShadow(
                color: navy.withOpacity(.055),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xffFFF0E3),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: notification.data?.logo == null || notification.data?.logo == ''
                      ? const Icon(Icons.notifications_active_rounded, color: orange, size: 27)
                      : CustomImage(
                          path: notification.data?.logo ?? '',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          type: ImageType.network,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.data?.title ?? '',
                            style: const TextStyle(
                              color: navy,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xffF5F6F8),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule_rounded, color: Color(0xff9AA0AA), size: 13),
                              const SizedBox(width: 3),
                              Text(
                                DateMethods.timeAgo(notification.createdAt ?? AppLocaleKey.now.tr(), context),
                                style: const TextStyle(
                                  color: Color(0xff8B929D),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notification.data?.text ?? '',
                      style: const TextStyle(
                        color: softText,
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (notificationType == 1 || notificationType == 3) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.locale.languageCode == 'ar' ? 'عرض التفاصيل' : 'View details',
                            style: const TextStyle(color: orange, fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            context.locale.languageCode == 'ar'
                                ? Icons.chevron_left_rounded
                                : Icons.chevron_right_rounded,
                            color: orange,
                            size: 17,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
