import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../global/partner/partner_identity.dart';
import '../../notification/controller/notifications_delegate_Controller.dart';
import '../../notification/screen/notification_delegate_screen.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../auth/controller/auth_controller.dart';
import '../../order/controller/partner_orders_controller.dart';
import '../../order/widget/partner_orders_board.dart';
import '../../delegate_bottom_nav_bar.dart/controller/delegate_bottom_nav_bar_controller.dart';
import '../../my_account/screen/delegate_reports_screen.dart';
import '../../my_account/screen/help_screen.dart';
import '../widget/delegate_status_widget.dart';
import '../widget/my_current_balance_card.dart';
import 'location_delegate.dart';

class HomeDelegateScreen extends StatefulWidget {
  static const String routeName = 'HomeDelegateScreen';
  const HomeDelegateScreen({super.key});

  @override
  State<HomeDelegateScreen> createState() => _HomeDelegateScreenState();
}

class _HomeDelegateScreenState extends State<HomeDelegateScreen> {
  static const _orange = PartnerIdentity.orange;
  static const _ink = PartnerIdentity.ink;
  bool get _ar => context.locale.languageCode == 'ar';
  String _t(String ar, String en) => _ar ? ar : en;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    final professional =
        profile?.isGoPartner == true &&
        profile?.partnerProfessionKey != null &&
        profile?.partnerProfessionKey != 'delivery_courier';
    final profession = _ar
        ? profile?.partnerProfessionNameAr
        : profile?.partnerProfessionNameEn;
    final name = profile?.name?.trim().isNotEmpty == true
        ? profile!.name!.trim()
        : _t('الشريك', 'Partner');
    final area = profile?.areaTitle?.trim().isNotEmpty == true
        ? profile!.areaTitle!
        : _t('موقعك الحالي', 'Current location');
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: _orange,
        onRefresh: context.read<PartnerOrdersController>().refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            children: [
              _header(
                name,
                area,
                isProfessionalPartner: professional,
                professionName: profession ?? '',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    PartnerOrdersBoard(
                      onViewAll: () => context
                          .read<DelegateBottomNavBarController>()
                          .updateIndex(1),
                    ),
                    const SizedBox(height: 20),
                    const MyCurrentBalanceWidget(),
                    const SizedBox(height: 28),
                    _quickActions(),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(
    String name,
    String area, {
    required bool isProfessionalPartner,
    required String professionName,
  }) {
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
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: _locationPill(area),
                    ),
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
                  decoration: BoxDecoration(
                    color: PartnerIdentity.ink,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xff3B2B20),
                        child: Icon(
                          Icons.waving_hand_outlined,
                          color: PartnerIdentity.orange,
                          size: 27,
                        ),
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isProfessionalPartner && professionName.isNotEmpty
                                  ? professionName
                                  : _t(
                                      'جاهز للعمل اليوم؟',
                                      'Ready to work today?',
                                    ),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (context.read<AuthController>().profile?.walletBlock ==
                    0) ...[
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
        onTap: () => NavigatorMethods.pushNamed(
          context,
          DelegateLocationScreen.routeName,
        ),
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
              const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 17,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  area,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 16,
              ),
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
              const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 25,
              ),
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xffE51B23),
                    shape: BoxShape.circle,
                  ),
                ),
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
        () => NavigatorMethods.pushNamed(
          context,
          DelegateReportsScreen.routeName,
        ),
      ),
      _QuickAction(
        _t('الخريطة', 'Map'),
        Icons.map_outlined,
        () => NavigatorMethods.pushNamed(
          context,
          DelegateLocationScreen.routeName,
        ),
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
              decoration: BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              context.watch<AuthController>().profile?.isGoPartner == true &&
                      context
                              .watch<AuthController>()
                              .profile
                              ?.partnerProfessionKey !=
                          'delivery_courier'
                  ? _t('أدوات الشريك', 'Partner tools')
                  : _t('أدوات المندوب', 'Driver tools'),
              style: const TextStyle(
                color: _ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
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
                style: const TextStyle(
                  color: Color(0xff202124),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
