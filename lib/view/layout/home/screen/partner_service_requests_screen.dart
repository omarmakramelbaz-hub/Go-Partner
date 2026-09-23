import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../order/screen/partner_orders_screen.dart';
import '../../order/widget/partner_orders_scope.dart';

/// Compatibility entry point for service-request notifications.
class PartnerServiceRequestsScreen extends StatelessWidget {
  const PartnerServiceRequestsScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  Widget build(BuildContext context) => PartnerOrdersScope(
    child: Scaffold(
      backgroundColor: Colors.white,
      appBar: embedded
          ? null
          : CustomAppBar(
              context,
              title: Text(
                context.locale.languageCode == 'ar' ? 'الطلبات' : 'Requests',
              ),
            ),
      body: const PartnerOrdersScreen(),
    ),
  );
}
