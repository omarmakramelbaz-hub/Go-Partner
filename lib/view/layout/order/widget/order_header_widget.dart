import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/utils/date_methods.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../model/delegate_order_model.dart';

class OrderHeaderWidget extends StatelessWidget {
  final DelegateOrdersModel? order;
  final bool isShipped;

  const OrderHeaderWidget({super.key, this.order, required this.isShipped});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF171A1F);
    const softText = Color(0xff7D8490);
    const orange = Color(0xffFD7201);
    final hasLogo = order?.userLogo != null && order!.userLogo!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xffFFF0E3),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: const Color(0xffFFE1C7)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CustomImage(
                path: hasLogo ? order?.userLogo ?? '' : AppImages.userIcon,
                type: hasLogo ? ImageType.network : ImageType.svg,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order?.userName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: navy, fontSize: 16.5, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocaleKey.orderNumber.tr().replaceAll('{}', order?.orderNo ?? ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: softText, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 15, color: Color(0xff9AA0AA)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${DateMethods.formatToDate(order?.createdAt?.toString() ?? '')}  ${DateMethods.formatToTime(order?.createdAt?.toString() ?? '')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xff8B929D),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xffFFF0E3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isShipped ? AppLocaleKey.shippingOrder.tr() : AppLocaleKey.restaurantOrder.tr(),
              style: const TextStyle(color: orange, fontSize: 11.5, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
