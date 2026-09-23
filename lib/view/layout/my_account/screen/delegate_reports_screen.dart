import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../custom_widgets/custom_table/custome_table.dart';
import '../controller/delegate_account_controller.dart';
import '../model/reports_model.dart';

class DelegateReportsScreen extends StatefulWidget {
  static const routeName = 'DelegateReportsScreen';
  const DelegateReportsScreen({super.key});

  @override
  State<DelegateReportsScreen> createState() => _DelegateReportsScreenState();
}

class _DelegateReportsScreenState extends State<DelegateReportsScreen> {
  String selectedTimeFrame = 'week';
  final List<String> timeFrames = ['day', 'week', 'month', 'year'];

  double calculateTotalOrderPrice(List<Orders> orders) {
    return orders.fold<double>(0, (total, order) => total + (order.deliveryPrice ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF171A1F);
    const softText = Color(0xff7D8490);

    return ChangeNotifierProvider(
      create: (_) => DelegateAccountController()
        ..initialDelegateReports()
        ..getDelegateReports(reportType: selectedTimeFrame),
      child: Consumer<DelegateAccountController>(
        builder: (context, controller, _) {
          final reports = controller.reports;
          final totalOrderPrice = calculateTotalOrderPrice(reports?.orders ?? []);

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: CustomAppBar(
              context,
              height: 86,
              title: Text(
                AppLocaleKey.myReports.tr(),
                style: const TextStyle(color: navy, fontSize: 21, fontWeight: FontWeight.w900),
              ),
            ),
            body: ApiResponseWidget(
              apiResponse: controller.reportsResponse,
              onReload: () => controller.getDelegateReports(reportType: selectedTimeFrame),
              isEmpty: reports == null,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.locale.languageCode == 'ar' ? 'ملخص الأداء' : 'Performance summary',
                                style: const TextStyle(color: navy, fontSize: 20, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.locale.languageCode == 'ar'
                                    ? 'تابع الطلبات والأرباح خلال الفترة المحددة'
                                    : 'Track orders and earnings for the selected period',
                                style: const TextStyle(color: softText, fontSize: 12.5, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xffECEEF1)),
                            boxShadow: [
                              BoxShadow(
                                color: navy.withOpacity(.05),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedTimeFrame,
                              borderRadius: BorderRadius.circular(18),
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xffFD7201)),
                              items: timeFrames
                                  .map(
                                    (value) => DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value.tr(),
                                        style: const TextStyle(color: navy, fontSize: 12.5, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => selectedTimeFrame = value);
                                controller.getDelegateReports(reportType: value);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 1.6,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _StatCard(
                          icon: Icons.inventory_2_outlined,
                          label: AppLocaleKey.receivedOrdersCount.tr(),
                          value: AppLocaleKey.order.tr().replaceAll('{}', '${reports?.ordersCount ?? 0}'),
                          accent: const Color(0xffFD7201),
                          surface: const Color(0xffFFF0E3),
                        ),
                        _StatCard(
                          icon: Icons.trending_up_rounded,
                          label: AppLocaleKey.receivedAmount.tr(),
                          value: AppLocaleKey.pound.tr().replaceAll(
                            '{}',
                            double.tryParse(reports?.totalGainFromApp.toString() ?? '')?.toStringAsFixed(2) ?? '0',
                          ),
                          accent: const Color(0xff16A36A),
                          surface: const Color(0xffEAF8F2),
                        ),
                        _StatCard(
                          icon: Icons.payments_outlined,
                          label: AppLocaleKey.paidAmount.tr(),
                          value: AppLocaleKey.pound.tr().replaceAll(
                            '{}',
                            double.tryParse(reports?.totalCashOrder.toString() ?? '')?.toStringAsFixed(2) ?? '0',
                          ),
                          accent: const Color(0xff5F6B7A),
                          surface: const Color(0xffEEF0F3),
                        ),
                        _StatCard(
                          icon: Icons.account_balance_wallet_outlined,
                          label: AppLocaleKey.forwardReceivables.tr(),
                          value: AppLocaleKey.pound.tr().replaceAll(
                            '{}',
                            double.tryParse(reports?.notTransferCashOrders.toString() ?? '')?.toStringAsFixed(2) ?? '0',
                          ),
                          accent: const Color(0xffC28B08),
                          surface: const Color(0xffFFF7DB),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xffFFF0E3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: Color(0xffFD7201), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          AppLocaleKey.orders.tr(),
                          style: const TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(23),
                        border: Border.all(color: const Color(0xffECEEF1)),
                        boxShadow: [
                          BoxShadow(
                            color: navy.withOpacity(.05),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: CustomAppTable(
                          columns: [
                            AppLocaleKey.user.tr(),
                            AppLocaleKey.reportOrderNumber.tr(),
                            AppLocaleKey.deliveryCost.tr(),
                            AppLocaleKey.deliveryMethod.tr(),
                            AppLocaleKey.applicationPercentage.tr(),
                          ],
                          rows: List.generate(
                            reports?.orders?.length ?? 0,
                            (index) {
                              final order = reports?.orders?[index];
                              return DataRow(
                                cells: [
                                  DataCell(Center(child: Text(order?.userName ?? ''))),
                                  DataCell(Center(child: Text(order?.orderNo ?? ''))),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        AppLocaleKey.pound.tr().replaceAll(
                                          '{}',
                                          order?.deliveryPrice?.toStringAsFixed(2) ?? '',
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        order?.type == 'shipping'
                                            ? AppLocaleKey.shippingOrder.tr()
                                            : order?.resturantName ?? '',
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        AppLocaleKey.pound.tr().replaceAll(
                                          '{}',
                                          double.tryParse(order?.appPercentage.toString() ?? '')?.toStringAsFixed(2) ?? '',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF171A1F),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Text(
                            AppLocaleKey.totalPrice.tr(),
                            style: TextStyle(color: Colors.white.withOpacity(.76), fontSize: 13.5, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Text(
                            AppLocaleKey.pound.tr().replaceAll('{}', totalOrderPrice.toStringAsFixed(2)),
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.surface,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xffECEEF1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF171A1F).withOpacity(.045),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, color: accent, size: 19),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xff7D8490), fontSize: 10.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF171A1F), fontSize: 14.5, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
