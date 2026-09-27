import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/go_services/service_api.dart';
import '../lib/go_services/partner_service_board.dart';

class MemoryAdapter implements HttpClientAdapter {
  MemoryAdapter(this.handler);
  final ResponseBody Function(RequestOptions) handler;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancel) async { requests.add(options); return handler(options); }
  @override
  void close({bool force = false}) {}
}
ResponseBody reply(Map<String, dynamic> data, [int code = 200]) => ResponseBody.fromString(jsonEncode({'status': 'Success', 'data': data}), code, headers: {Headers.contentTypeHeader: ['application/json']});
ServiceApi api(MemoryAdapter adapter) => ServiceApi(dio: Dio()..httpClientAdapter = adapter, baseUrl: 'https://example.invalid/api/', token: () => 'test-token-not-real');
Map<String, dynamic> exampleJob() => {'id': 7, 'status': 'searching', 'recipient_status': 'invited', 'description': 'Repair kitchen sink', 'area': 'District', 'search_until': DateTime.now().add(const Duration(hours: 1)).toIso8601String(), 'offers': <dynamic>[]};
void main() {
  for (final ar in [true, false]) {
    testWidgets('cancellation shows liability and posts only after fee consent and reason ($ar)', (tester) async {
      final job = {...exampleJob(), 'status': 'booked', 'accepted_offer_id': 3, 'price': '100.00', 'payment_status': 'cash_due', 'payment_method': 'cash',
        'commission': '12.50', 'commission_rate': '12.50', 'commission_status': 'charged',
        'cancellation': {'allowed': true, 'requires_fee_confirmation': true, 'fee': '12.50', 'rate': '12.50'},
        'offers': [{'id': 3, 'status': 'accepted', 'price': '100.00', 'scope': 'Repair pipe'}]};
      final adapter = MemoryAdapter((r) => r.path.endsWith('capabilities') ? reply({'schema_ready': true, 'version': 1, 'enabled': true}) : reply(r.method == 'POST' ? {...job, 'status': 'cancelled'} : job));
      final client = api(adapter);
      await tester.pumpWidget(MaterialApp(home: PartnerServiceJobScreen(api: client, ar: ar, id: 7)));
      await tester.pumpAndSettle();
      final cancel = find.text(ar ? 'إلغاء وتحمل خدمة التطبيق' : 'Cancel and bear the app fee');
      await tester.scrollUntilVisible(cancel, 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(cancel); await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.textContaining('12.50')), findsOneWidget);
      expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
      await tester.tap(find.widgetWithText(TextButton, ar ? 'رجوع' : 'Back')); await tester.pumpAndSettle();
      expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
      await tester.tap(cancel); await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, ar ? 'تأكيد' : 'Confirm')); await tester.pumpAndSettle();
      expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
      await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), 'Changed plans');
      await tester.tap(find.widgetWithText(FilledButton, ar ? 'تأكيد' : 'Confirm')); await tester.pumpAndSettle();
      final post = adapter.requests.singleWhere((r) => r.method == 'POST');
      expect(post.data['cancellation_fee'], '12.50'); expect(post.data['reason'], 'Changed plans'); expect(post.data['status'], 'cancelled');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox()); client.close();
    });
  }

  for (final ar in [true, false]) {
    for (final permitted in [false, true]) {
      testWidgets('customer phone requires selected quote and server commission permission (Arabic=$ar, permitted=$permitted)', (tester) async {
        final job = {...exampleJob(), 'status': 'booked', 'accepted_offer_id': 3, 'phone': '01012345678', if (permitted) 'can_contact_customer': true, 'location': {'address': 'Building 4, apartment 3', 'lat': 30, 'lng': 31}, 'offers': [{'id': 3, 'status': 'accepted', 'price': '500.00'}]};
        final client = api(MemoryAdapter((r) => r.path.endsWith('capabilities') ? reply({'schema_ready': true, 'version': 1, 'enabled': true}) : reply(job)));
        await tester.pumpWidget(MaterialApp(home: PartnerServiceJobScreen(api: client, ar: ar, id: 7)));
        await tester.pumpAndSettle();
        expect(find.text('Building 4, apartment 3'), findsOneWidget);
        expect(find.textContaining('01012345678'), permitted ? findsOneWidget : findsNothing);
        expect(find.text(ar ? 'افتح موقع التنفيذ' : 'Open work location'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox()); client.close();
      });
    }
  }
  for (final ar in [true, false]) {
    for (final feeStatus in ['charged', 'refunded']) {
      testWidgets('agreed job shows saved percentage and fee ($ar, $feeStatus)', (tester) async {
        final job = {...exampleJob(), 'status': feeStatus == 'refunded' ? 'cancelled' : 'booked', 'accepted_offer_id': 3,
          'price': '101.01', 'commission': '12.63', 'commission_rate': '12.50', 'account_commission_rate': '30.00',
          'commission_status': feeStatus, 'payment_status': 'cash_due',
          'offers': [{'id': 3, 'status': 'accepted', 'price': '101.01', 'commission': '12.63', 'commission_rate': '12.50'}]};
        final client = api(MemoryAdapter((r) => r.path.endsWith('capabilities') ? reply({'schema_ready': true, 'version': 1, 'enabled': true}) : reply(job)));
        await tester.pumpWidget(MaterialApp(home: PartnerServiceJobScreen(api: client, ar: ar, id: 7, rate: '40.00')));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.textContaining(ar ? 'نسبة خدمة التطبيق: 12.50%' : 'App service fee rate: 12.50%'), 200, scrollable: find.byType(Scrollable).first);
        expect(find.textContaining('12.63'), findsOneWidget);
        expect(find.textContaining('30.00%'), findsNothing);
        expect(find.textContaining('40.00%'), findsNothing);
        final expected = feeStatus == 'refunded' ? (ar ? 'تم رد خدمة التطبيق' : 'The app service fee was refunded') : (ar ? 'تم الخصم من محفظتك' : 'Debited from your wallet on customer acceptance');
        expect(find.textContaining(expected), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox()); client.close();
      });
    }
    testWidgets('orders board shows quote percentage and expected debit before acceptance ($ar)', (tester) async {
      final job = {...exampleJob(), 'recipient_status': 'quoted', 'offers': [{'id': 3, 'status': 'offered', 'price': '200.00', 'commission_rate': '7.50', 'commission': '15.00'}]};
      final client = api(MemoryAdapter((r) => r.path.endsWith('capabilities') ? reply({'schema_ready': true, 'version': 1, 'enabled': true}) : reply({'items': [job], 'balance': '100.00', 'commission_rate': '10.00'})));
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: PartnerServiceBoard(api: client, ar: ar, legacyBuilder: (_) => const SizedBox())))));
      await tester.pumpAndSettle();
      expect(find.textContaining(ar ? 'نسبة خدمة التطبيق: 7.50%' : 'App service fee rate: 7.50%'), findsOneWidget);
      expect(find.textContaining('15.00'), findsOneWidget);
      expect(find.textContaining(ar ? 'تخصم من محفظتك فقط عند قبول العميل' : 'Debited from your wallet only when'), findsOneWidget);
      expect(find.textContaining(ar ? 'تم الخصم' : 'No second charge'), findsNothing);
      await tester.pumpWidget(const SizedBox()); client.close();
    });
  }
  testWidgets('explicit zero rate displays zero and missing historical rate stays unknown', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: partnerCommission(false, {'commission_rate': '0.00', 'commission': '0.00'}, status: 'charged'))));
    expect(find.text('App service fee rate: 0.00%'), findsOneWidget);
    expect(find.text('App service fee: EGP 0.00'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: partnerCommission(false, {'commission': '5.00'}, status: 'unconfirmed'))));
    expect(find.text('App service fee rate: —'), findsOneWidget);
    expect(find.textContaining('No second charge'), findsNothing);
  });
  test('exact prices and Arabic digits; invalid or over-limit prices rejected', () {
    expect(normalizeServicePrice('١٢٣٫٤٥'), '123.45'); expect(normalizeServicePrice('1.2'), '1.20');
    for (final value in ['0', '-1', '0.99', '1.001', 'NaN', '1e3', '1000000.01']) { expect(normalizeServicePrice(value), isNull); }
    for (var i = 100; i < 1100; i++) { final value = '${i ~/ 100}.${(i % 100).toString().padLeft(2, '0')}'; expect(normalizeServicePrice(value), value); }
  });
  test('only an invited eligible-state job allows a new quote', () {
    final job = exampleJob(); expect(serviceCanQuote(job), isTrue);
    expect(serviceCanQuote({...job, 'recipient_status': 'declined'}), isFalse);
    expect(serviceCanQuote({...job, 'offers': [{'id': 1}]}), isFalse);
    expect(serviceCanQuote({...job, 'search_until': 'invalid'}), isFalse);
    expect(serviceCanQuote({...job, 'status': 'booked'}), isFalse);
  });
  test('another professional winning cannot unlock fulfillment controls', () {
    expect(serviceSelected({'accepted_offer_id': 5, 'offers': [{'id': 3, 'status': 'closed'}]}), isFalse);
    expect(serviceSelected({'accepted_offer_id': 5, 'offers': [{'id': 5, 'status': 'accepted'}]}), isTrue);
    expect(serviceSelected({'offers': [{'status': 'accepted'}]}), isFalse);
  });
  test('old backend fallback differs from network/server failure', () async {
    final old = api(MemoryAdapter((_) => reply({}, 404))); expect((await old.capabilities()).ready, isFalse); old.close();
    final broken = api(MemoryAdapter((_) => reply({}, 503))); await expectLater(broken.capabilities(), throwsA(isA<ServiceFailure>())); broken.close();
  });
  test('quotation posts exact scope and decimal price with partner scope', () async {
    final adapter = MemoryAdapter((_) => reply(exampleJob())); final client = api(adapter);
    final data = {'price': '500.00', 'scope': 'Fix the connection', 'materials_included': false, 'arrival_minutes': 30, 'duration_minutes': 60};
    await client.quote(7, data); expect(adapter.requests.single.path, endsWith('/jobs/7/offers')); expect(adapter.requests.single.data, data); expect(adapter.requests.single.headers['X-App-Scope'], 'go_partner');
    expect((adapter.requests.single.data as Map).containsKey('commission'), isFalse); client.close();
  });
  test('skip and fulfillment are POST; no client-side balance writes', () async {
    final adapter = MemoryAdapter((_) => reply(exampleJob())); final client = api(adapter);
    await client.skip(7); await client.status(7, 'awaiting_confirmation');
    expect(adapter.requests.every((r) => r.method == 'POST'), isTrue); expect(adapter.requests.last.data, {'status': 'awaiting_confirmation'}); client.close();
  });
  test('public capabilities do not carry a bearer token', () async {
    final adapter = MemoryAdapter((_) => reply({'schema_ready': true, 'version': 1, 'enabled': true})); final client = api(adapter);
    await client.capabilities(); expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse); client.close();
  });
  testWidgets('unavailable quotes are explicit and original requests stay on the board', (tester) async {
    final client = api(MemoryAdapter((_) => reply({}, 404)));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PartnerServiceBoard(api: client, ar: false, legacyBuilder: (_) => const Text('legacy board')))));
    await tester.pumpAndSettle();
    expect(find.text('Labour quotations are currently unavailable'), findsOneWidget);
    expect(find.text('legacy board'), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); client.close();
  });
  testWidgets('board recovers after server activation without restarting the app', (tester) async {
    var ready = false;
    final adapter = MemoryAdapter((r) => r.path.endsWith('capabilities')
      ? reply({'schema_ready': ready, 'version': 1, 'enabled': ready})
      : reply({'items': [exampleJob()], 'balance': '100.00', 'commission_rate': '10.00'}));
    final client = api(adapter);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: PartnerServiceBoard(api: client, ar: false, legacyBuilder: (_) => const Text('legacy board'))))));
    await tester.pumpAndSettle();
    expect(find.text('Labour quotations are currently unavailable'), findsOneWidget);
    ready = true;
    await tester.pump(const Duration(seconds: 15)); await tester.pumpAndSettle();
    expect(find.text('Repair kitchen sink'), findsOneWidget);
    expect(find.text('Labour quotations are currently unavailable'), findsNothing);
    expect(adapter.requests.where((r) => r.path.endsWith('capabilities')), hasLength(2));
    expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
    await tester.pumpWidget(const SizedBox()); client.close();
  });
  testWidgets('new jobs use the customer requests board and expose quote action', (tester) async {
    final adapter = MemoryAdapter((r) => r.path.endsWith('capabilities') ? reply({'schema_ready': true, 'version': 1, 'enabled': true}) : reply(exampleJob())); final client = api(adapter);
    await tester.pumpWidget(MaterialApp(home: PartnerServiceJobScreen(api: client, ar: false, id: 7)));
    await tester.pumpAndSettle(); expect(find.text('Send labour quote'), findsOneWidget); expect(find.text('Start work'), findsNothing); expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
    await tester.pumpWidget(const SizedBox()); client.close();
  });
  testWidgets('unpaid agreed jobs cannot start work', (tester) async {
    final job = {...exampleJob(), 'status': 'booked', 'accepted_offer_id': 3, 'payment_status': 'unpaid', 'price': '500.00', 'commission': '50.00', 'offers': [{'id': 3, 'status': 'accepted', 'price': '500.00'}]};
    final adapter = MemoryAdapter((r) => r.path.endsWith('capabilities') ? reply({'schema_ready': true, 'version': 1, 'enabled': true}) : reply(job)); final client = api(adapter);
    await tester.pumpWidget(MaterialApp(home: PartnerServiceJobScreen(api: client, ar: false, id: 7)));
    await tester.pumpAndSettle(); expect(find.text('Start work'), findsNothing);
    await tester.pumpWidget(const SizedBox()); client.close();
  });
  testWidgets('quote submission requires explicit final-scope consent', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PartnerQuoteForm(ar: false, rate: '10.00'))));
    await tester.pumpAndSettle(); expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Send quote')).onPressed, isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
