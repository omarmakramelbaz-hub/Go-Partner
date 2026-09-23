import 'dart:convert';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../controller/delegate_order_controller.dart';
import '../model/delegate_order_model.dart';
import '../widget/on_going_orders_delegate_widget.dart';
import '../widget/previous_orders_delegate_widget.dart';
import '../widget/waiting_delegate_tap.dart';

class OrdersDelegateScreen extends StatefulWidget {
  const OrdersDelegateScreen({super.key});

  @override
  State<OrdersDelegateScreen> createState() => _OrdersDelegateScreenState();
}

class _OrdersDelegateScreenState extends State<OrdersDelegateScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PusherController _pusherController;

  @override
  void initState() {
    super.initState();
    _pusherController = context.read<PusherController>();
    _tabController = TabController(length: 3, vsync: this)..addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _pusherController.addEventListener('delegate.updated', _handleDelegateUpdated);
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  void _handleDelegateUpdated(PusherEvent event) {
    try {
      final decodedData = json.decode(event.data) as Map<String, dynamic>;
      final orderData = decodedData['order_id'];
      if (!mounted || orderData is! Map<String, dynamic>) return;
      final orderModel = DelegateOrdersModel.fromJson(orderData);
      _loadData();
      if (orderModel.status == 'declined' || orderModel.status == 'cancelled') _loadData();
    } catch (e, stackTrace) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $stackTrace');
    }
  }

  void _loadData() {
    if (!mounted) return;
    final controller = context.read<DelegateOrdersController>();
    controller.initialDelegateCompletedOrders();
    controller.initialDelegateOngoingOrders();
    controller.initialDelegateWaitingOrders();
    Future.wait([
      controller.getDelegateWaitingOrders(),
      controller.getDelegateOngoingOrders(),
      controller.getDelegateCompletedOrders(),
    ]);
  }

  @override
  void dispose() {
    _pusherController.removeEventListener('delegate.updated', _handleDelegateUpdated);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff171A1F);
    const softText = Color(0xff7D8490);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<DelegateOrdersController>(
        builder: (context, controller, _) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 50,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: const Color(0xffEEF0F3), borderRadius: BorderRadius.circular(12)),
                  child: TabBar(
                    controller: _tabController,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: const Color(0xffFD7201),
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [BoxShadow(color: navy.withOpacity(.08), blurRadius: 12, offset: const Offset(0, 5))],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: softText,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 3),
                    labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                    unselectedLabelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    onTap: (_) => setState(() {}),
                    tabs: [
                      _OrderTab(
                        label: AppLocaleKey.pending.tr(),
                        count: controller.totalWaiting,
                        selected: _tabController.index == 0,
                      ),
                      _OrderTab(
                        label: AppLocaleKey.ongoing.tr(),
                        count: controller.ongoingOrders?.meta?.total ?? 0,
                        selected: _tabController.index == 1,
                      ),
                      _OrderTab(
                        label: AppLocaleKey.previous.tr(),
                        count: controller.completedOrders?.meta?.total ?? 0,
                        selected: _tabController.index == 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      WaitingOrdersDelegateWidget(delegateOrderController: controller),
                      OnGoingOrdersDelegateWidget(delegateOrderController: controller),
                      PreviousOrdersDelegateWidget(delegateOrderController: controller),
                    ],
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

class _OrderTab extends StatelessWidget {
  const _OrderTab({required this.label, required this.count, required this.selected});

  final String label;
  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 5),
            Container(
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? Colors.white.withOpacity(.22) : const Color(0xffE3E6EA),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xff68707B),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
