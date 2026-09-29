import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/go_stores/store_api.dart';
import '../lib/go_stores/store_orders_screen.dart';
import '../lib/helpers/networking/sound_notification.dart';

Map<String, dynamic> orderFixture() => {'id': 24, 'number': 'GS-24', 'revision': 1, 'status': 'pending',
  'store_name': 'ماركت الأميرة', 'store_address': 'مدينة مبارك', 'customer_name': 'عميل تجريبي', 'customer_mobile': '01000000000',
  'fulfillment': 'pickup', 'items': [{'product_id': 5, 'name': 'أرز', 'unit': 'كيلو', 'option_label': 'نصف كيلو', 'quantity': 2, 'unit_price': '42.75', 'line_total': '85.50'}],
  'subtotal': '85.50', 'delivery': '0.00', 'total': '85.50', 'commission_rate': '10.00', 'commission': '8.55',
  'payment_method': 'cash', 'payment_status': 'cash_due', 'actions': ['accept', 'reject']};

class FixtureStoreApi extends StoreApi {
  FixtureStoreApi() : super(token: () => 'fixture');
  Map<String, dynamic> current = orderFixture();
  bool empty = false;
  final actions = <Map<String, dynamic>>[];
  @override
  Future<Map<String, dynamic>> orders({bool history = false, int page = 1}) async => {'orders': empty || history ? [] : [current], 'page': 1, 'last_page': 1, 'total': empty ? 0 : 1};
  @override
  Future<Map<String, dynamic>> order(int id) async => {'order': current};
  @override
  Future<Map<String, dynamic>> orderAction(int id, String action, int revision, {String? reason}) async {
    actions.add({'id': id, 'action': action, 'revision': revision, 'reason': reason});
    current = {...current, 'revision': revision + 1, 'status': action == 'accept' ? 'preparing' : action == 'reject' ? 'rejected' : action == 'ready' ? 'ready' : 'completed',
      'actions': action == 'accept' ? ['ready'] : action == 'ready' ? ['complete'] : <String>[]};
    return {'order': current};
  }
}
Widget app(Widget child, {bool ar = true}) => MaterialApp(locale: Locale(ar ? 'ar' : 'en'), supportedLocales: const [Locale('ar'), Locale('en')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates, theme: ThemeData(fontFamily: 'Tajawal'), home: child);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Tajawal')..addFont(rootBundle.load('assets/font/Tajawal/Tajawal-Regular.ttf'))..addFont(rootBundle.load('assets/font/Tajawal/Tajawal-Bold.ttf'))).load();
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  test('store notification sound has its own order identity', () {
    expect(incomingOrderSoundKey({'notification_type': '12', 'go_store_order_id': '24', 'notification_sound': 'long'}), 'store:24');
    expect(incomingOrderSoundKey({'notification_type': '12', 'go_store_order_id': '24', 'notification_sound': 'default'}), isNull);
  });
  testWidgets('merchant inbox recovers new orders without manual refresh', (tester) async {
    final api = FixtureStoreApi()..empty = true;
    int? count;
    await tester.pumpWidget(app(StoreOrdersScreen(api: api, onPendingCount: (v) => count = v)));
    await tester.pumpAndSettle(); expect(find.text('لا توجد طلبات هنا حاليًا'), findsOneWidget);
    api.empty = false; await tester.pump(const Duration(seconds: 5)); await tester.pumpAndSettle();
    expect(find.textContaining('GS-24'), findsOneWidget); expect(count, 1);
    await tester.tap(find.text('السابقة')); await tester.pumpAndSettle();
    expect(find.textContaining('GS-24'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  for (final ar in [true, false]) {
    testWidgets('merchant sees items payment and commission then accepts / ar=$ar', (tester) async {
      tester.view.physicalSize = const Size(390, 1400); tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
      final api = FixtureStoreApi(); final boundary = GlobalKey();
      await tester.pumpWidget(app(RepaintBoundary(key: boundary, child: StoreOrderDetailsScreen(orderId: 24, api: api)), ar: ar));
      await tester.pumpAndSettle();
      expect(find.text('GS-24'), findsOneWidget); expect(find.textContaining('8.55'), findsOneWidget); expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image = await (boundary.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final directory = Directory(Platform.environment['GO_STORE_SCREENSHOTS'] ?? 'build/ui-preview'); await directory.create(recursive: true);
        await File('${directory.path}/store-order-${ar ? 'ar' : 'en'}.png').writeAsBytes(bytes!.buffer.asUint8List()); image.dispose();
      });
      await tester.ensureVisible(find.byKey(const ValueKey('store-order-accept')));
      await tester.tap(find.byKey(const ValueKey('store-order-accept'))); await tester.pumpAndSettle();
      expect(find.textContaining(ar ? 'تُخصم عند القبول' : 'charged on acceptance'), findsOneWidget);
      await tester.tap(find.text(ar ? 'تأكيد' : 'Confirm')); await tester.pumpAndSettle();
      expect(api.actions.single['action'], 'accept'); expect(api.actions.single['revision'], 1);
      expect(find.byKey(const ValueKey('store-order-ready')), findsOneWidget); expect(find.byKey(const ValueKey('store-order-reject')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('decline requires a reason before sending action', (tester) async {
    final api = FixtureStoreApi();
    await tester.pumpWidget(app(StoreOrderDetailsScreen(orderId: 24, api: api))); await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('store-order-reject'))); await tester.tap(find.byKey(const ValueKey('store-order-reject'))); await tester.pumpAndSettle();
    await tester.tap(find.text('تأكيد')); await tester.pumpAndSettle(); expect(api.actions, isEmpty);
    await tester.enterText(find.byType(TextFormField), 'المنتج غير متاح');
    await tester.tap(find.text('تأكيد')); await tester.pumpAndSettle();
    expect(api.actions.single['reason'], 'المنتج غير متاح'); expect(find.text('رفض المتجر الطلب'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
