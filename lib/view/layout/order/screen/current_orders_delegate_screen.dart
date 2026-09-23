import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../custom_widgets/custom_loading/custom_loading.dart';
import '../../../global/widget/order_delegate_widget.dart';
import '../../home/controller/delegate_home_controller.dart';

class CurrentOrdersDelegateArgs {
  final VoidCallback onPop;
  CurrentOrdersDelegateArgs({required this.onPop});
}

class CurrentOrdersDelegateScreen extends StatefulWidget {
  static const String routeName = 'CurrentOrdersDelegateScreen';
  final CurrentOrdersDelegateArgs args;

  const CurrentOrdersDelegateScreen({super.key, required this.args});

  @override
  State<CurrentOrdersDelegateScreen> createState() => _CurrentOrdersDelegateScreenState();
}

class _CurrentOrdersDelegateScreenState extends State<CurrentOrdersDelegateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<HomeDelegateController>();
      controller.initialCurrentDelegateOrders();
      controller.getCurrentDelegateOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF171A1F);
    const softText = Color(0xff7D8490);

    return Consumer<HomeDelegateController>(
      builder: (context, controller, _) {
        return PopScope(
          canPop: true,
          onPopInvoked: (didPop) {
            if (didPop) widget.args.onPop();
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: CustomAppBar(
              context,
              height: 86,
              appBarColor: const Color(0xff171A1F),
              title: Text(
                AppLocaleKey.currentOrders.tr(),
                style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900),
              ),
            ),
            body: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.pixels == notification.metrics.maxScrollExtent &&
                    controller.currentOrdersHasPagination &&
                    !controller.currentIsPaginating) {
                  controller.getCurrentDelegateOrders();
                }
                return true;
              },
              child: ApiResponseWidget(
                apiResponse: controller.currentDelegateOrdersResponse,
                onReload: controller.getCurrentDelegateOrders,
                isEmpty: controller.currentDelegateOrders.isEmpty,
                child: RefreshIndicator(
                  color: const Color(0xffFD7201),
                  onRefresh: controller.getCurrentDelegateOrders,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xffECEEF1)),
                          boxShadow: [
                            BoxShadow(color: navy.withOpacity(.055), blurRadius: 18, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xffFFF0E3),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.delivery_dining_rounded, color: Color(0xffFD7201), size: 23),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocaleKey.currentOrders.tr(),
                                    style: const TextStyle(color: navy, fontSize: 17, fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    context.locale.languageCode == 'ar'
                                        ? 'الطلبات التي تعمل عليها الآن'
                                        : 'Orders you are currently working on',
                                    style: const TextStyle(
                                      color: softText,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xffFF8A08), Color(0xffFF6500)]),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Text(
                                controller.currentOrders?.meta?.total.toString() ?? '0',
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(controller.currentDelegateOrders.length + 1, (index) {
                        if (index == controller.currentDelegateOrders.length) {
                          return controller.currentIsPaginating
                              ? const Padding(
                                  padding: EdgeInsets.all(18),
                                  child: Center(child: CustomLoading()),
                                )
                              : const SizedBox.shrink();
                        }
                        final order = controller.currentDelegateOrders[index];
                        return OrderDelegateWidget(
                          isDelivered: false,
                          orderId: order.id ?? 0,
                          order: order,
                          orderItem: order.delegateItems,
                          onsuccess: () => controller.getCurrentDelegateOrders(pageNumber: 1),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
