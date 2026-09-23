import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../helpers/locale/app_locale_key.dart';
import '../partner/partner_identity.dart';

class NoCurrentOrderWidget extends StatelessWidget {
  const NoCurrentOrderWidget({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 12),
    child: Column(
      children: [
        const CircleAvatar(
          radius: 34,
          backgroundColor: Color(0xffF1F3F5),
          child: Icon(Icons.assignment_outlined, color: PartnerIdentity.ink, size: 31),
        ),
        const SizedBox(height: 20),
        Text(
          AppLocaleKey.noOrders.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(color: PartnerIdentity.ink, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          context.locale.languageCode == 'ar'
              ? 'ستظهر الطلبات هنا حسب حالتها فور وصولها'
              : 'Orders will appear here by status as they arrive',
          textAlign: TextAlign.center,
          style: const TextStyle(color: PartnerIdentity.muted, fontSize: 13, height: 1.5),
        ),
      ],
    ),
  );
}
