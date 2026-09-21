import 'dart:convert';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/networking/notification_helper.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../../global/chat/screen/admin_chat_screen.dart';
import '../../../global/chat/screen/chat_screen.dart';
import '../../auth/controller/auth_controller.dart';
import '../../home/screen/home_delegate_screen.dart';
import '../../home/screen/location_delegate.dart';
import '../../home/screen/partner_service_requests_screen.dart';
import '../../my_account/screen/my_account_delegate_screen.dart';
import '../../notification/model/notfication_from_firebase_model.dart';
import '../../notification/screen/notification_delegate_screen.dart';
import '../../order/screen/order_delegate_screen.dart';
import '../../order/screen/order_details_delegate_screen.dart';
import '../../wallet/screen/wallet_screen.dart';
import '../controller/delegate_bottom_nav_bar_controller.dart';

class DelegateBottomNavBarScreen extends StatefulWidget {
  static const String routeName = 'DelegateBottomNavBarScreen';
  const DelegateBottomNavBarScreen({super.key});

  @override
  State<DelegateBottomNavBarScreen> createState() => _DelegateBottomNavBarScreenState();
}

class _DelegateBottomNavBarScreenState extends State<DelegateBottomNavBarScreen> {
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
      _pusherController!.addEventListener('delegate.updated', _handleDelegateUpdated);
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
          CommonMethods.showToast(message: '${AppLocaleKey.thereIsANewOrder.tr()} $orderNo');
        } else {
          CommonMethods.showToast(message: '${AppLocaleKey.thereIsANewOrderWithStatus.tr()} $orderNo');
        }
      }
    } catch (e, stackTrace) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    _pusherController?.removeEventListener('delegate.updated', _handleDelegateUpdated);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff171A1F);

    return ChangeNotifierProvider(
      create: (_) => DelegateBottomNavBarController(),
      child: Consumer<DelegateBottomNavBarController>(
        builder: (context, controller, _) {
          final profile = context.watch<AuthController>().profile;
          final isProfessionalPartner = profile?.isGoPartner == true &&
              profile?.partnerProfessionKey != null &&
              profile?.partnerProfessionKey != 'delivery_courier';

          final pages = <Widget>[
            const HomeDelegateScreen(),
            isProfessionalPartner
                ? const PartnerServiceRequestsScreen()
                : const OrdersDelegateScreen(),
            const WalletScreen(),
            const MyAccountDelegateScreen(),
          ];

          return PopScope(
            canPop: controller.screenIndex == 0,
            onPopInvoked: controller.onWillPop,
            child: Scaffold(
              backgroundColor: const Color(0xffF5F7FA),
              extendBody: true,
              resizeToAvoidBottomInset: false,
              appBar: controller.screenIndex == 0
                  ? null
                  : PreferredSize(
                      preferredSize: const Size.fromHeight(88),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: () => NavigatorMethods.pushNamed(context, DelegateLocationScreen.routeName),
                              child: Container(
                                height: 70,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: const Color(0xffECEEF1)),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xfffff8f2), Colors.white],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: navy.withOpacity(.07),
                                      blurRadius: 22,
                                      offset: const Offset(0, 9),
                                    ),
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
                                      child: const Icon(
                                        Icons.location_on_rounded,
                                        color: Color(0xffFD7201),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            AppLocaleKey.address.tr(),
                                            style: const TextStyle(
                                              color: Color(0xff7D8490),
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            context.watch<AuthController>().profile?.areaTitle ?? '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: navy,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: const Color(0xffF7F8FA),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        context.locale.languageCode == 'ar'
                                            ? Icons.chevron_left_rounded
                                            : Icons.chevron_right_rounded,
                                        color: const Color(0xffFD7201),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
              body: IndexedStack(index: controller.screenIndex, children: pages),
              bottomNavigationBar: SafeArea(
                minimum: const EdgeInsets.fromLTRB(12, 0, 12, 9),
                child: Container(
                  height: 82,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(29),
                    border: Border.all(color: const Color(0xffE8ECF1)),
                    boxShadow: [
                      BoxShadow(
                        color: navy.withOpacity(.13),
                        blurRadius: 32,
                        offset: const Offset(0, 13),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _NavItem(
                        label: AppLocaleKey.home.tr(),
                        activeIcon: AppImages.homeFillIcon,
                        inactiveIcon: AppImages.homeIcon,
                        selected: controller.screenIndex == 0,
                        onTap: () => controller.updateIndex(0),
                      ),
                      _NavItem(
                        label: isProfessionalPartner
                            ? (context.locale.languageCode == 'ar'
                                ? 'طلبات الخدمات'
                                : 'Service requests')
                            : AppLocaleKey.orders.tr(),
                        activeIcon: AppImages.orderFillIcon,
                        inactiveIcon: AppImages.ordersIcon,
                        selected: controller.screenIndex == 1,
                        onTap: () => controller.updateIndex(1),
                      ),
                      _NavItem(
                        label: context.locale.languageCode == 'ar' ? 'المحفظة' : 'Wallet',
                        activeIcon: AppImages.walletIcon,
                        inactiveIcon: AppImages.walletIcon,
                        selected: controller.screenIndex == 2,
                        onTap: () => controller.updateIndex(2),
                      ),
                      _NavItem(
                        label: AppLocaleKey.myAccount.tr(),
                        activeIcon: AppImages.accountFillIcon,
                        inactiveIcon: AppImages.myAccountIcon,
                        selected: controller.screenIndex == 3,
                        onTap: () => controller.updateIndex(3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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
          arguments: OrderDetailsDelegateScreenArgs(fromHome: false, orderId: int.parse(data.orderId.toString())),
        );
        break;
      case '3':
        NavigatorMethods.pushNamed(AppRouters.navigatorKey.currentContext ?? context, WalletScreen.routeName);
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
  final String activeIcon;
  final String inactiveIcon;
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
                  height: 35,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xffFFF0E3) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SvgPicture.asset(
                    selected ? activeIcon : inactiveIcon,
                    width: 23,
                    height: 23,
                    colorFilter: ColorFilter.mode(
                      selected ? const Color(0xffFD7201) : const Color(0xff929AA5),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? const Color(0xff171A1F) : const Color(0xff8B929D),
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
