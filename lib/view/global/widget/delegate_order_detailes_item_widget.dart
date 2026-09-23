import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../helpers/locale/app_locale_key.dart';
import '../../custom_widgets/custom_image/custom_image.dart';
import '../../layout/order/model/delegate_order_model.dart';

class OrderDelegateDetailsItemWidget extends StatelessWidget {
  const OrderDelegateDetailsItemWidget({super.key, required this.items});

  final DelegateItems? items;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF171A1F);
    const softText = Color(0xff7D8490);
    const orange = Color(0xffFD7201);

    final feature = items?.productFeatureName == 'kilo'
        ? AppLocaleKey.kilo.tr()
        : items?.productFeatureName == 'quarter'
            ? AppLocaleKey.quarter.tr()
            : items?.productFeatureName == 'half'
                ? AppLocaleKey.half.tr()
                : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: const Color(0xffFAFAFB),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: const Color(0xffECEEF1)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CustomImage(
                height: 78,
                width: 92,
                path: items?.resturantProduct?.productImage ?? '',
                type: ImageType.network,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    items?.resturantProduct?.productName ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: navy, fontSize: 14.5, height: 1.35, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocaleKey.pound.tr().replaceAll('{}', '${items?.price ?? 0}'),
                    style: const TextStyle(color: orange, fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                  if (feature.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      '${AppLocaleKey.quantity.tr().replaceAll('{}', '')} $feature',
                      style: const TextStyle(color: softText, fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(minWidth: 42, minHeight: 38),
              padding: const EdgeInsets.symmetric(horizontal: 9),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xffFFF0E3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '×${items?.qty ?? 0}',
                style: const TextStyle(color: navy, fontSize: 13, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
