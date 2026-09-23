import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../global/partner/partner_identity.dart';
import '../controller/partner_orders_controller.dart';
import '../widget/partner_orders_board.dart';
import 'order_delegate_screen.dart';

class PartnerOrdersScreen extends StatefulWidget {
  const PartnerOrdersScreen({super.key});
  @override
  State<PartnerOrdersScreen> createState() => _PartnerOrdersScreenState();
}

class _PartnerOrdersScreenState extends State<PartnerOrdersScreen> {
  int _section = 0;
  @override
  Widget build(BuildContext context) {
    final orders = context.watch<PartnerOrdersController>();
    final ar = context.locale.languageCode == 'ar';
    return RefreshIndicator(
      onRefresh: orders.refresh,
      color: PartnerIdentity.orange,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (!orders.isProfessional)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                icon: const Icon(Icons.search_rounded, size: 19),
                label: Text(
                  ar ? 'بحث وتصفية طلبات التوصيل' : 'Search delivery orders',
                ),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => Scaffold(
                        appBar: CustomAppBar(
                          context,
                          title: Text(
                            ar ? 'البحث في الطلبات' : 'Search orders',
                          ),
                        ),
                        body: const OrdersDelegateScreen(),
                      ),
                    ),
                  );
                  if (mounted) await orders.refresh();
                },
              ),
            ),
          Row(
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: TextButton(
                      onPressed: () {
                        setState(() => _section = i);
                        if (i == 2) orders.loadHistory();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: _section == i
                            ? PartnerIdentity.orange
                            : const Color(0xffF2F3F5),
                        foregroundColor: _section == i
                            ? Colors.white
                            : PartnerIdentity.ink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        (ar
                            ? ['الجديدة', 'الجارية', 'السابقة']
                            : ['New', 'Current', 'History'])[i],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          PartnerOrdersBoard(section: _section),
        ],
      ),
    );
  }
}
