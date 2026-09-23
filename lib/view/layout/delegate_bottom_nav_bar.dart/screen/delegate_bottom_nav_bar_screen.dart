import 'dart:convert';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/networking/notification_helper.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../../global/chat/screen/admin_chat_screen.dart';
import '../../../global/chat/screen/chat_screen.dart';
import '../../../global/partner/partner_identity.dart';
import '../../auth/controller/auth_controller.dart';
import '../../home/screen/home_delegate_screen.dart';
import '../../home/screen/location_delegate.dart';
import '../../home/screen/partner_service_requests_screen.dart';
import '../../my_account/screen/my_account_delegate_screen.dart';
import '../../notification/model/notfication_from_firebase_model.dart';
import '../../order/screen/partner_orders_screen.dart';
import '../../order/widget/partner_orders_scope.dart';
import '../../order/screen/order_details_delegate_screen.dart';
import '../../wallet/screen/wallet_screen.dart';
import '../controller/delegate_bottom_nav_bar_controller.dart';

class DelegateBottomNavBarScreen extends StatefulWidget {
  static const String routeName = 'DelegateBottomNavBarScreen';
  const DelegateBottomNavBarScreen({super.key});

  @override
  State<DelegateBottomNavBarScreen> createState() =>
      _DelegateBottomNavBarScreenState();
}

class _DelegateBottomNavBarScreenState
    extends State<DelegateBottomNavBarScreen> {
  PusherController? _pusherController;
  FirebaseMessaging? _messaging;
  NotificationHelper? _notificationHelper;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _messaging = FirebaseMessaging.instance;
      _notificationHelper = NotificationHelper();
      _initialNotification();
      _pusherController = context.read<PusherController>();
      _pusherController!.addEventListener(
        'delegate.updated',
        _handleDelegateUpdated,
      );
    }
  }

  void _handleDelegateUpdated(PusherEvent event) {
    try {
      final jsonData = jsonDecode(event.data) as Map<String, dynamic>;
      if (mounted) {
        final status = jsonData['order_id']['status']?.toString();
        final orderNo = jsonData['order_id']['order_no']?.toString();
        log(jsonData.toString());
        if (status == 'pending') {
          SoundNotification.instance.playLongSound();
          CommonMethods.showToast(
            message: '${AppLocaleKey.thereIsANewOrder.tr()} $orderNo',
          );
        } else {
          CommonMethods.showToast(
            message: '${AppLocaleKey.thereIsANewOrderWithStatus.tr()} $orderNo',
          );
        }
      }
    } catch (e, stackTrace) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    _pusherController?.removeEventListener(
      'delegate.updated',
      _handleDelegateUpdated,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PartnerOrdersScope(
      child: ChangeNotifierProvider(
        create: (_) => DelegateBottomNavBarController(),
        child: Consumer<DelegateBottomNavBarController>(
          builder: (context, controller, _) {
            final profile = context.watch<AuthController>().profile;
            final pages = <Widget>[
              const HomeDelegateScreen(),
              const PartnerOrdersScreen(),
              const WalletScreen(embedded: true),
              const MyAccountDelegateScreen(),
            ];

            return PopScope(
              canPop: controller.screenIndex == 0,
              onPopInvoked: controller.onWillPop,
              child: Scaffold(
                backgroundColor: PartnerIdentity.ink,
                extendBody: false,
                resizeToAvoidBottomInset: false,
                appBar: controller.screenIndex == 0
                    ? null
                    : PartnerTabHeader(
                        title: controller.screenIndex == 1
                            ? AppLocaleKey.orders.tr()
                            : controller.screenIndex == 2
                            ? AppLocaleKey.wallet.tr()
                            : AppLocaleKey.myAccount.tr(),
                        location: profile?.areaTitle ?? '',
                        onLocationTap: () => NavigatorMethods.pushNamed(
                          context,
                          DelegateLocationScreen.routeName,
                        ),
                        onBack: () => controller.updateIndex(0),
                      ),
                body: IndexedStack(
                  index: controller.screenIndex,
                  children: [
                    pages.first,
                    for (final page in pages.skip(1))
                      PartnerSurface(child: page),
                  ],
                ),
                bottomNavigationBar: ColoredBox(
                  color: Colors.white,
                  child: SafeArea(
                    minimum: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.zero,
                        border: const Border(
                          top: BorderSide(color: PartnerIdentity.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          _NavItem(
                            label: AppLocaleKey.home.tr(),
                            activeIcon: Icons.home_rounded,
                            inactiveIcon: Icons.home_outlined,
                            selected: controller.screenIndex == 0,
                            onTap: () => controller.updateIndex(0),
                          ),
                          _NavItem(
                            label: AppLocaleKey.orders.tr(),
                            activeIcon: Icons.assignment_rounded,
                            inactiveIcon: Icons.assignment_outlined,
                            selected: controller.screenIndex == 1,
                            onTap: () => controller.updateIndex(1),
                          ),
                          _NavItem(
                            label: context.locale.languageCode == 'ar'
                                ? 'المحفظة'
                                : 'Wallet',
                            activeIcon: Icons.account_balance_wallet_outlined,
                            inactiveIcon: Icons.account_balance_wallet_outlined,
                            selected: controller.screenIndex == 2,
                            onTap: () => controller.updateIndex(2),
                          ),
                          _NavItem(
                            label: AppLocaleKey.myAccount.tr(),
                            activeIcon: Icons.person_rounded,
                            inactiveIcon: Icons.person_outline_rounded,
                            selected: controller.screenIndex == 3,
                            onTap: () => controller.updateIndex(3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _initialNotification() {
    final messaging = _messaging;
    if (messaging == null) return;

    messaging.getInitialMessage().then((message) {
      if (message != null) {
        log('${message.notification?.title}');
        log('${message.notification?.body}');
        log(message.data.toString());
        SoundNotification.instance.stopSound();
        _onNotificationTaped(message);
      }
    });
    FirebaseMessaging.onMessage.listen((message) {
      log('${message.notification?.title}');
      log('${message.notification?.body}');
      log(message.data.toString());
      _notificationHelper?.display(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      SoundNotification.instance.stopSound();
      _onNotificationTaped(message);
    });
    _requestPermission();
  }

  Future<NotificationSettings?> _requestPermission() async {
    return _messaging?.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  void _onNotificationTaped(RemoteMessage message) {
    log('Navigating to From Bottom Nav Bar');
    SoundNotification.instance.stopSound();
    final msg = json.encode(message.data);
    final body = json.decode(msg);
    final data = NotificationFromFirebaseMode.fromJson(body);
    switch (data.notificationType.toString()) {
      case '1':
        NavigatorMethods.pushNamed(
          AppRouters.navigatorKey.currentContext ?? context,
          OrderDetailsDelegateScreen.routeName,
          arguments: OrderDetailsDelegateScreenArgs(
            fromHome: false,
            orderId: int.parse(data.orderId.toString()),
          ),
        );
        break;
      case '3':
        NavigatorMethods.pushNamed(
          AppRouters.navigatorKey.currentContext ?? context,
          WalletScreen.routeName,
        );
        break;
      case '7':
        Navigator.of(AppRouters.navigatorKey.currentContext ?? context).push(
          MaterialPageRoute(
            builder: (_) => const PartnerServiceRequestsScreen(),
          ),
        );
        break;
      case '8':
        NavigatorMethods.pushNamed(
          AppRouters.navigatorKey.currentContext!,
          ChatScreen.routeName,
          arguments: ChatScreenArgs(
            senderDeviceToken: data.receiverDeviceToken.toString(),
            accountType: data.accountType.toString(),
            isVendor: false,
            vendorDeviceToken: data.receiverDeviceToken.toString(),
            receiverDeviceToken: data.senderDeviceToken.toString(),
            senderName: data.receiverName.toString(),
            receiverName: data.senderName.toString(),
            orderId: data.orderId.toString(),
          ),
        );
        break;
      case '10':
        NavigatorMethods.pushNamed(
          AppRouters.navigatorKey.currentContext!,
          AdminChatScreen.routeName,
          arguments: AdminChatScreenArgs(
            senderId: data.receiverId.toString(),
            receiverId: data.senderId.toString(),
            receiverDeviceToken: data.senderDeviceToken.toString(),
            senderDeviceToken: data.receiverDeviceToken.toString(),
            senderName: data.receiverName.toString(),
            receiverName: data.senderName.toString(),
            accountType: data.accountType.toString(),
            isToVendor: true,
            vendorDeviceToken: data.receiverDeviceToken.toString(),
          ),
        );
        break;
      default:
        NavigatorMethods.pushNamed(
          AppRouters.navigatorKey.currentContext ?? context,
          DelegateBottomNavBarScreen.routeName,
        );
    }
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(3, 7, 3, 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 210),
                  curve: Curves.easeOutCubic,
                  width: 47,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xffFFF0E3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    selected ? activeIcon : inactiveIcon,
                    size: 23,
                    color: selected
                        ? PartnerIdentity.orange
                        : PartnerIdentity.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? PartnerIdentity.orange
                        : PartnerIdentity.muted,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 210),
                  width: selected ? 30 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xffFD7201),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
