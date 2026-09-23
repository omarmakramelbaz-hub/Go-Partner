import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_partner/helpers/networking/api_helper.dart';
import 'package:go_partner/helpers/pusher_service/pusher_controller.dart';
import 'package:go_partner/helpers/routes/app_routers_import.dart';
import 'package:go_partner/helpers/theme/app_theme_controller.dart';
import 'package:go_partner/helpers/theme/style.dart';
import 'package:go_partner/view/global/partner/partner_identity.dart';
import 'package:go_partner/view/layout/auth/controller/auth_controller.dart';
import 'package:go_partner/view/layout/auth/model/profile_model.dart';
import 'package:go_partner/view/layout/my_account/controller/my_account_controller.dart';
import 'package:go_partner/view/layout/my_account/model/setting_model.dart';
import 'package:go_partner/view/layout/my_account/screen/my_account_delegate_screen.dart';
import 'package:go_partner/view/layout/order/controller/delegate_order_controller.dart';
import 'package:go_partner/view/layout/order/screen/order_delegate_screen.dart';
import 'package:go_partner/view/layout/wallet/controller/wallet_controller.dart';
import 'package:go_partner/view/layout/wallet/model/wallet_model.dart';
import 'package:go_partner/view/layout/wallet/screen/wallet_screen.dart';
import 'package:go_partner/view/layout/home/controller/delegate_home_controller.dart';
import 'package:go_partner/view/layout/home/screen/home_delegate_screen.dart';
import 'package:go_partner/view/layout/notification/screen/notification_delegate_screen.dart';
import 'package:go_partner/view/layout/delegate_bottom_nav_bar.dart/controller/delegate_bottom_nav_bar_controller.dart';

final translations = <String, Map<String, dynamic>>{};
class TestTranslations extends AssetLoader {
  const TestTranslations();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => translations[locale.languageCode]!;
}

class PreviewAuth extends AuthController {
  @override
  ProfileModel get profile => ProfileModel(id: 1, name: 'شريك GO', mobile: '01000000000', areaTitle: 'المنصورة', balance: 1938.25);
  @override
  Future<void> getProfile({void Function(int id, String token)? onHaveId, VoidCallback? onSuccess, VoidCallback? onUnauthenticated}) async {}
}

class PreviewHome extends HomeDelegateController {
  @override
  Future<void> getPendingDelegateHomeOrders({int? pageNumber}) async {}
  @override
  Future<void> getCurrentDelegateHomeOrders({int? pageNumber}) async {}
  @override
  Future<void> getCurrentDelegateOrdersHome() async {}
  @override
  Future<void> getOngoingDelegateOrdersHome() async {}
}
class PreviewSettings extends MyAccountController {
  PreviewSettings({this.enabled = true});
  final bool enabled;
  @override
  SettingModel get setting =>
      SettingModel(walletCardActivate: enabled ? 'true' : 'false', paymentCardActivate: 'false');
}

class PreviewWallet extends WalletController {
  ResponseState state = ResponseState.complete;
  int refreshes = 0;
  @override
  WalletModel get wallet => WalletModel(balance: 1938.25, wallet: []);
  @override
  ApiResponse get walletResponse => ApiResponse(state: state, data: null);
  @override
  Future<void> getWallet() async {
    refreshes++;
    state = ResponseState.complete;
    notifyListeners();
  }
}

class PreviewOrders extends DelegateOrdersController {
  @override
  ApiResponse get delegateWaitingOrdersResponse => ApiResponse(state: ResponseState.complete, data: null);
  @override
  ApiResponse get delegateOngoingOrdersResponse => ApiResponse(state: ResponseState.complete, data: null);
  @override
  ApiResponse get delegateCompletedOrdersResponse => ApiResponse(state: ResponseState.complete, data: null);
  @override
  bool get waitingOrdersHasPagination => false;
  @override
  bool get onGoingOrdersHasPagination => false;
  @override
  bool get completedOrdersHasPagination => false;
  @override
  Future<void> getDelegateWaitingOrders({int? pageNumber, int? orderNo}) async {}
  @override
  Future<void> getDelegateCompletedOrders({int? pageNumber, int? orderNo}) async {}
  @override
  Future<void> getDelegateOngoingOrders({
    int? pageNumber,
    int? orderNo,
    String? delegateFromOut,
    String? type,
    String? date,
  }) async {}
}

Widget harness(Widget child, {String language = 'ar'}) => EasyLocalization(
  supportedLocales: const [Locale('ar'), Locale('en')],
  startLocale: Locale(language),
  saveLocale: false,
  path: 'i18n',
  assetLoader: const TestTranslations(),
  child: MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppThemeController()),
      ChangeNotifierProvider<AuthController>(create: (_) => PreviewAuth()),
      ChangeNotifierProvider(create: (_) => PusherController()),
      ChangeNotifierProvider<DelegateOrdersController>(create: (_) => PreviewOrders()),
    ],
    child: Builder(
      builder: (context) => MaterialApp(
        navigatorKey: AppRouters.navigatorKey,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        theme: appThemeData(context),
        home: RepaintBoundary(key: const ValueKey('capture'), child: child),
      ),
    ),
  ),
);

Widget page(String title, Widget body) => Scaffold(
  backgroundColor: PartnerIdentity.ink,
  appBar: PartnerTabHeader(title: title, location: 'المنصورة', onLocationTap: () {}, onBack: () {}),
  body: PartnerSurface(child: body),
);

Future<void> capture(WidgetTester tester, String name) async {
  final directory = Platform.environment['GO_PARTNER_SNAPSHOTS'];
  if (directory == null) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('capture')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(directory).create(recursive: true);
    await File('$directory/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory hiveDirectory;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    for (final language in ['ar', 'en']) {
      translations[language] = jsonDecode(File('i18n/$language.json').readAsStringSync()) as Map<String, dynamic>;
    }
    hiveDirectory = await Directory.systemTemp.createTemp('partner-ui-test');
    Hive.init(hiveDirectory.path);
    await Hive.openBox('app');
    final fonts = FontLoader('Tajawal')
      ..addFont(rootBundle.load('assets/font/Tajawal/Tajawal-Regular.ttf'))
      ..addFont(rootBundle.load('assets/font/Tajawal/Tajawal-Bold.ttf'));
    await fonts.load();
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (call) async => ['none'],
    );
  });
  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  for (final embedded in [true, false]) {
    testWidgets('wallet owns its providers when opened ${embedded ? 'as a tab' : 'as a route'}', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        harness(embedded ? page('المحفظة', const WalletScreen(embedded: true)) : const WalletScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(WalletContent), findsOneWidget);
      final context = tester.element(find.byType(WalletContent));
      expect(context.read<WalletController>().walletResponse.state, ResponseState.offline);
      expect(context.read<MyAccountController>(), isA<MyAccountController>());
      expect(find.text('تأكد من الاتصال بالإنترنت'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 390.0]) {
      testWidgets('wallet balance and actions fit $language at $width', (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final wallet = PreviewWallet();
        await tester.pumpWidget(
          harness(
            page(
              language == 'ar' ? 'المحفظة' : 'Wallet',
              MultiProvider(
                providers: [
                  ChangeNotifierProvider<WalletController>.value(value: wallet),
                  ChangeNotifierProvider<MyAccountController>(create: (_) => PreviewSettings()),
                ],
                child: const WalletContent(embedded: true),
              ),
            ),
            language: language,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('1938.25'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byIcon(Icons.refresh_rounded));
        await tester.pumpAndSettle();
        expect(wallet.refreshes, 1);
        if (language == 'ar' && width == 390) await capture(tester, 'wallet');
        await tester.pumpWidget(const SizedBox());
        wallet.dispose();
      });
    }
  }

  testWidgets('home branding fits and the bell opens notifications', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(harness(MultiProvider(providers: [
      ChangeNotifierProvider<HomeDelegateController>(create: (_) => PreviewHome()),
      ChangeNotifierProvider(create: (_) => DelegateBottomNavBarController()),
    ], child: const HomeDelegateScreen())));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capture(tester, 'home');
    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsDelegateScreen), findsOneWidget);
    expect(find.byType(WalletScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled charging remains unavailable', (tester) async {
    await tester.pumpWidget(
      harness(
        page(
          'المحفظة',
          MultiProvider(
            providers: [
              ChangeNotifierProvider<WalletController>(create: (_) => PreviewWallet()),
              ChangeNotifierProvider<MyAccountController>(create: (_) => PreviewSettings(enabled: false)),
            ],
            child: const WalletContent(embedded: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.add_rounded), findsNothing);
    expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('orders and account keep readable Arabic layouts on a phone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(harness(page('الطلبات', const OrdersDelegateScreen())));
    await tester.pumpAndSettle();
    expect(find.byType(TabBar), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capture(tester, 'orders');
    await tester.drag(find.byType(TabBarView), const Offset(350, 0));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(harness(page('حسابي', const MyAccountDelegateScreen())));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.person_outline_rounded), findsWidgets);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capture(tester, 'account');
  });
}
