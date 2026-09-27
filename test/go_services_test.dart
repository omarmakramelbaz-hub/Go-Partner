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
  testWidgets('unavailable quotes are explicit and original requests remain accessible', (tester) async {
    final client = api(MemoryAdapter((_) => reply({}, 404)));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PartnerServiceBoard(api: client, ar: false, legacyBuilder: (_) => const Text('legacy board')))));
    await tester.pumpAndSettle();
    expect(find.text('Labour quotations are currently unavailable'), findsOneWidget);
    expect(find.text('legacy board'), findsNothing);
    await tester.tap(find.text('View requests in the previous system')); await tester.pumpAndSettle();
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
