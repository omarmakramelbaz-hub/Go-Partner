import 'dart:convert';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../global/partner/partner_identity.dart';
import '../../notification/controller/notifications_delegate_Controller.dart';
import '../../notification/screen/notification_delegate_screen.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../auth/controller/auth_controller.dart';
import '../../delegate_bottom_nav_bar.dart/controller/delegate_bottom_nav_bar_controller.dart';
import '../../my_account/screen/delegate_reports_screen.dart';
import '../../my_account/screen/help_screen.dart';
import '../../order/model/delegate_order_model.dart';
import '../../order/screen/order_details_delegate_screen.dart';
import '../controller/delegate_home_controller.dart';
import '../widget/delegate_status_widget.dart';
import '../widget/my_current_balance_card.dart';
import 'location_delegate.dart';
import 'partner_service_requests_screen.dart';

class HomeDelegateScreen extends StatefulWidget {
  static const String routeName = 'HomeDelegateScreen';
  const HomeDelegateScreen({super.key});

  @override
  State<HomeDelegateScreen> createState() => _HomeDelegateScreenState();
}

class _HomeDelegateScreenState extends State<HomeDelegateScreen> {
  late PusherController _pusherController;

  static const _orange = Color(0xffFF7200);
  static const _orange2 = Color(0xffFF9200);
  static const _ink = Color(0xff161616);
  static const _surface = Colors.white;

  bool _isRefreshingOrders = false;

  bool get _ar => context.locale.languageCode == 'ar';
  String _t(String ar, String en) => _ar ? ar : en;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
    _pusherController = context.read<PusherController>();
    _pusherController.addEventListener('delegate.updated', _onPusher);
  }

  Future<void> _refreshData() async {
    final controller = context.read<HomeDelegateController>();
    controller.initialPendingDelegateHomeOrders();
    controller.initialCurrentDelegateHomeOrders();
    await Future.wait([
      controller.getPendingDelegateHomeOrders(),
      controller.getCurrentDelegateHomeOrders(),
      controller.getCurrentDelegateOrdersHome(),
      controller.getOngoingDelegateOrdersHome(),
    ]);
  }

  Future<void> _refreshOrdersFromButton() async {
    if (_isRefreshingOrders) return;
    setState(() => _isRefreshingOrders = true);
    try {
      await _refreshData();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_t('تم تحديث الطلبات', 'Orders updated')),
            duration: const Duration(milliseconds: 1200),
          ),
        );
    } catch (e, s) {
      log('Manual order refresh error: $e');
      log('$s');
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(_t('تعذر تحديث الطلبات، حاول مرة أخرى', 'Could not refresh orders. Try again.')),
              duration: const Duration(milliseconds: 1600),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _isRefreshingOrders = false);
    }
  }

  void _onPusher(PusherEvent event) {
    try {
      json.decode(event.data);
      if (mounted) _refreshData();
    } catch (e, s) {
      log('Home pusher error: $e');
      log('$s');
    }
  }

  @override
  void dispose() {
    _pusherController.removeEventListener('delegate.updated', _onPusher);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Consumer<HomeDelegateController>(
        builder: (context, controller, _) {
          final profile = context.watch<AuthController>().profile;
          final isProfessionalPartner =
              profile?.isGoPartner == true &&
              profile?.partnerProfessionKey != null &&
              profile?.partnerProfessionKey != 'delivery_courier';
          final professionName = _ar
              ? (profile?.partnerProfessionNameAr ?? '')
              : (profile?.partnerProfessionNameEn ?? '');
          final name = profile?.name?.trim().isNotEmpty == true
              ? profile!.name!.trim()
              : (isProfessionalPartner ? _t('الشريك', 'Partner') : _t('المندوب', 'Driver'));
          final area = profile?.areaTitle?.trim().isNotEmpty == true
              ? profile!.areaTitle!.trim()
              : _t('موقعك الحالي', 'Current location');
          final currentOrder = controller.currentDelegateHomeOrders.isNotEmpty
              ? controller.currentDelegateHomeOrders.first
              : null;

          final currentCount = controller.currentHomeOrders?.meta?.total ?? 0;
          final pendingCount = controller.totalPending;
          final totalCount = pendingCount + currentCount;

          return RefreshIndicator(
            color: _orange,
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              child: Column(
                children: [
                  _header(name, area, isProfessionalPartner: isProfessionalPartner, professionName: professionName),
                  Transform.translate(
                    offset: const Offset(0, 0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        children: [
                          if (isProfessionalPartner)
                            _professionalPartnerHero(
                              professionName: professionName,
                              radiusKm: profile?.partnerWorkRadiusKm,
                            )
                          else
                            _currentOrderCard(currentOrder),
                          const SizedBox(height: 14),
                          if (!isProfessionalPartner) ...[
                            _statsRow(total: totalCount, pending: pendingCount, current: currentCount, completed: 0),
                            const SizedBox(height: 14),
                          ],
                          const MyCurrentBalanceWidget(),
                          const SizedBox(height: 14),
                          _professionalRequestsEntry(),
                          const SizedBox(height: 28),
                          _quickActions(),
                          const SizedBox(height: 74),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _header(String name, String area, {required bool isProfessionalPartner, required String professionName}) {
    return Column(
      children: [
        Container(
          color: PartnerIdentity.ink,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: Row(
                children: [
                  const PartnerWordmark(height: 44),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Align(alignment: AlignmentDirectional.centerEnd, child: _locationPill(area)),
                  ),
                  const SizedBox(width: 12),
                  _notificationButton(),
                ],
              ),
            ),
          ),
        ),
        PartnerSurface(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: PartnerIdentity.ink, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xff3B2B20),
                        child: Icon(Icons.waving_hand_outlined, color: PartnerIdentity.orange, size: 27),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _t('مرحبًا، $name', 'Welcome, $name'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isProfessionalPartner && professionName.isNotEmpty
                                  ? professionName
                                  : _t('جاهز للعمل اليوم؟', 'Ready to work today?'),
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (context.read<AuthController>().profile?.walletBlock == 0) ...[
                  const SizedBox(height: 12),
                  const DelegateStatusWidget(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _locationPill(String area) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => NavigatorMethods.pushNamed(context, DelegateLocationScreen.routeName),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: 126,
          height: 39,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(.16)),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.white, size: 17),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  area,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notificationButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider(
              create: (_) => NotificationsDelegateController(),
              child: const NotificationsDelegateScreen(),
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.16),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(.24)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 25),
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xffE51B23), shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _professionalPartnerHero({required String professionName, required int? radiusKm}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xff20242A), Color(0xff111419)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.verified_user_rounded, color: _orange, size: 31),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('حساب شريك GO معتمد', 'Verified GO Partner'),
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      professionName.isEmpty ? _t('مقدم خدمة محترف', 'Professional service provider') : professionName,
                      style: TextStyle(color: Colors.white.withOpacity(.78), fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: _partnerMetric(
                  Icons.location_searching_rounded,
                  _t('نطاق العمل', 'Work radius'),
                  radiusKm == null ? '—' : '$radiusKm ${_t('كم', 'km')}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _partnerMetric(
                  Icons.notifications_active_outlined,
                  _t('الطلبات', 'Requests'),
                  _t('استقبال مباشر', 'Live'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PartnerServiceRequestsScreen())),
              style: FilledButton.styleFrom(
                backgroundColor: _orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
              ),
              icon: const Icon(Icons.handyman_rounded),
              label: Text(
                _t('عرض طلبات الخدمات', 'View service requests'),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _partnerMetric(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.07),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withOpacity(.09)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _orange, size: 21),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withOpacity(.60), fontSize: 9.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _currentOrderCard(DelegateOrdersModel? order) {
    final hasOrder = order != null;
    final orderTitle = order?.resturantName?.trim().isNotEmpty == true
        ? order!.resturantName!.trim()
        : _t('طلب توصيل', 'Delivery order');
    final address = order?.resturantLocation?.trim().isNotEmpty == true
        ? order!.resturantLocation!.trim()
        : (order?.fromAddress?.trim().isNotEmpty == true
              ? order!.fromAddress!.trim()
              : _t('سيظهر عنوان الاستلام هنا', 'Pickup address will appear here'));
    final customer = order?.userName?.trim().isNotEmpty == true
        ? order!.userName!.trim()
        : _t('بيانات العميل', 'Customer details');

    return Container(
      height: 246,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xff171717),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.20), blurRadius: 28, offset: const Offset(0, 13))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _RoutePainter(active: hasOrder)),
            ),
            Positioned(
              left: -40,
              bottom: -45,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _orange.withOpacity(.10)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_orange2, _orange]),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 17),
                            const SizedBox(width: 6),
                            Text(
                              hasOrder ? _t('طلب حالي', 'Current order') : _t('لا يوجد طلب', 'No order'),
                              style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(.10)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.schedule_rounded, color: _orange, size: 17),
                            const SizedBox(width: 5),
                            Text(
                              hasOrder ? _t('جاري التنفيذ', 'In progress') : _t('جاهز', 'Ready'),
                              style: TextStyle(
                                color: Colors.white.withOpacity(.82),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    hasOrder
                        ? '#${order.orderNo ?? order.id ?? ''}'
                        : _t('بانتظار طلب جديد', 'Waiting for a new order'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 27, height: 1, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    hasOrder
                        ? orderTitle
                        : _t('أول ما تستلم طلب هيظهر هنا بكل تفاصيله', 'Your next accepted order will appear here'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withOpacity(.92), fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  if (hasOrder) ...[
                    _darkInfoRow(Icons.location_on_rounded, address),
                    const SizedBox(height: 6),
                    _darkInfoRow(Icons.person_outline_rounded, customer),
                  ] else
                    _darkInfoRow(
                      Icons.route_rounded,
                      _t('خليك متصل علشان تستقبل الطلبات فوراً', 'Stay online to receive orders instantly'),
                    ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: hasOrder && order.id != null
                              ? () => NavigatorMethods.pushNamed(
                                  context,
                                  OrderDetailsDelegateScreen.routeName,
                                  arguments: OrderDetailsDelegateScreenArgs(fromHome: true, orderId: order.id!),
                                )
                              : (_isRefreshingOrders ? null : _refreshOrdersFromButton),
                          borderRadius: BorderRadius.circular(19),
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [_orange2, _orange]),
                              borderRadius: BorderRadius.circular(19),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!hasOrder && _isRefreshingOrders)
                                  const SizedBox(
                                    width: 19,
                                    height: 19,
                                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                  )
                                else
                                  Icon(
                                    hasOrder ? Icons.navigation_rounded : Icons.refresh_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                const SizedBox(width: 7),
                                Text(
                                  hasOrder
                                      ? _t('متابعة التوصيل', 'Continue delivery')
                                      : (_isRefreshingOrders
                                            ? _t('جاري التحديث...', 'Refreshing...')
                                            : _t('تحديث الطلبات', 'Refresh orders')),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (hasOrder) ...[
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: order.id == null
                              ? null
                              : () => NavigatorMethods.pushNamed(
                                  context,
                                  OrderDetailsDelegateScreen.routeName,
                                  arguments: OrderDetailsDelegateScreenArgs(fromHome: true, orderId: order.id!),
                                ),
                          borderRadius: BorderRadius.circular(19),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.05),
                              borderRadius: BorderRadius.circular(19),
                              border: Border.all(color: Colors.white.withOpacity(.35)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _t('التفاصيل', 'Details'),
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _darkInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withOpacity(.72), fontSize: 10.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _statsRow({required int total, required int pending, required int current, required int completed}) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            value: total,
            label: _t('إجمالي', 'Total'),
            icon: Icons.inventory_2_rounded,
            tint: const Color(0xff2874F0),
            soft: const Color(0xffEEF4FF),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _MiniStat(
            value: pending,
            label: _t('انتظار', 'Pending'),
            icon: Icons.schedule_rounded,
            tint: _orange,
            soft: const Color(0xffFFF1E5),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _MiniStat(
            value: current,
            label: _t('تنفيذ', 'Active'),
            icon: Icons.delivery_dining_rounded,
            tint: const Color(0xff1E9E64),
            soft: const Color(0xffEAF9F1),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _MiniStat(
            value: completed,
            label: _t('مكتمل', 'Done'),
            icon: Icons.check_rounded,
            tint: const Color(0xff11A96C),
            soft: const Color(0xffE8F8F0),
          ),
        ),
      ],
    );
  }

  Widget _professionalRequestsEntry() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PartnerServiceRequestsScreen())),
        borderRadius: BorderRadius.circular(23),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xff20242A), Color(0xff111419)],
            ),
            borderRadius: BorderRadius.circular(23),
            boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 18, offset: Offset(0, 8))],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.handyman_rounded, color: _orange, size: 29),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('طلبات الخدمات والمهن', 'Professional service requests'),
                      style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _t(
                        'شاهد الطلبات المرسلة لك من العملاء حسب مهنتك ونطاق عملك',
                        'View customer requests matched to your profession and work area',
                      ),
                      style: TextStyle(
                        color: Colors.white.withOpacity(.72),
                        fontSize: 10.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const CircleAvatar(
                radius: 18,
                backgroundColor: _orange,
                child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActions() {
    final actions = <_QuickAction>[
      _QuickAction(
        _t('الإعدادات', 'Settings'),
        Icons.settings_outlined,
        () => context.read<DelegateBottomNavBarController>().updateIndex(3),
      ),
      _QuickAction(
        _t('تقاريري', 'Reports'),
        Icons.bar_chart_rounded,
        () => NavigatorMethods.pushNamed(context, DelegateReportsScreen.routeName),
      ),
      _QuickAction(
        _t('الخريطة', 'Map'),
        Icons.map_outlined,
        () => NavigatorMethods.pushNamed(context, DelegateLocationScreen.routeName),
      ),
      _QuickAction(
        _t('الدعم الفني', 'Support'),
        Icons.headset_mic_outlined,
        () => NavigatorMethods.pushNamed(context, HelpScreen.routeName),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 24,
              decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(6)),
            ),
            const SizedBox(width: 8),
            Text(
              context.watch<AuthController>().profile?.isGoPartner == true &&
                      context.watch<AuthController>().profile?.partnerProfessionKey != 'delivery_courier'
                  ? _t('أدوات الشريك', 'Partner tools')
                  : _t('أدوات المندوب', 'Driver tools'),
              style: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            for (int i = 0; i < actions.length; i++) ...[
              Expanded(child: _QuickActionCard(action: actions[i])),
              if (i != actions.length - 1) const SizedBox(width: 7),
            ],
          ],
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.tint,
    required this.soft,
  });

  final int value;
  final String label;
  final IconData icon;
  final Color tint;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xffE9EBEF)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.035), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(color: soft, shape: BoxShape.circle),
            child: Icon(icon, color: tint, size: 17),
          ),
          const SizedBox(height: 5),
          Text(
            '$value',
            style: const TextStyle(color: Color(0xff171717), fontSize: 18, height: 1, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xff6F747C), fontSize: 8.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});
  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 88,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xffE8EAEE)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: const Color(0xff202124), size: 25),
              const SizedBox(height: 7),
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xff202124), fontSize: 9.5, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.active});
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withOpacity(.035)
      ..strokeWidth = 1;
    for (double y = 25; y < size.height; y += 34) {
      canvas.drawLine(Offset(size.width * .47, y), Offset(size.width, y - 14), grid);
    }
    for (double x = size.width * .55; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x - 55, size.height), grid);
    }

    final route = Paint()
      ..color = active ? const Color(0xffFF7200) : Colors.white.withOpacity(.16)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * .60, size.height * .30)
      ..cubicTo(
        size.width * .66,
        size.height * .35,
        size.width * .70,
        size.height * .46,
        size.width * .73,
        size.height * .53,
      )
      ..cubicTo(
        size.width * .78,
        size.height * .62,
        size.width * .84,
        size.height * .60,
        size.width * .91,
        size.height * .72,
      );
    canvas.drawPath(path, route);

    final dot = Paint()..color = active ? const Color(0xffFF7200) : Colors.white.withOpacity(.28);
    canvas.drawCircle(Offset(size.width * .60, size.height * .30), 7, dot);
    canvas.drawCircle(Offset(size.width * .91, size.height * .72), 7, dot);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) => oldDelegate.active != active;
}
