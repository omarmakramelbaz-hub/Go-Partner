import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_partner/go_services/partner_service_board.dart';
import 'package:go_partner/go_services/service_api.dart';

const _ready = ServiceCapabilities(ready: true, enabled: true);

Map<String, dynamic> _job(String description) => {
  'id': 7,
  'description': description,
  'status': 'searching',
  'recipient_status': 'invited',
  'search_until': DateTime.now()
      .add(const Duration(hours: 1))
      .toIso8601String(),
  'offers': <dynamic>[],
};

Map<String, dynamic> _bookedJob(String description) => {
  ..._job(description),
  'status': 'booked',
  'accepted_offer_id': 3,
  'price': '100.00',
  'payment_status': 'cash_due',
  'offers': [
    {'id': 3, 'status': 'accepted', 'price': '100.00'},
  ],
};

class _ControlledApi extends ServiceApi {
  _ControlledApi({String? Function()? token})
    : super(token: token ?? () => 'test-session');

  final jobReads = <Completer<Map<String, dynamic>>>[];
  final capabilitiesReads = <Completer<ServiceCapabilities>>[];
  Map<String, dynamic>? skippedJob;
  int skips = 0;

  @override
  Future<Map<String, dynamic>> job(int id) {
    final read = Completer<Map<String, dynamic>>();
    jobReads.add(read);
    return read.future;
  }

  @override
  Future<ServiceCapabilities> capabilities() {
    final read = Completer<ServiceCapabilities>();
    capabilitiesReads.add(read);
    return read.future;
  }

  @override
  Future<Map<String, dynamic>> skip(int id) async {
    skips++;
    return skippedJob!;
  }
}

class _TimedApi extends ServiceApi {
  _TimedApi() : super(token: () => 'test-session');

  int jobReads = 0;
  int capabilitiesReads = 0;

  @override
  Future<Map<String, dynamic>> job(int id) {
    final read = ++jobReads;
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => _job('Server refresh $read'),
    );
  }

  @override
  Future<ServiceCapabilities> capabilities() {
    capabilitiesReads++;
    return Future.delayed(const Duration(milliseconds: 300), () => _ready);
  }
}

class _PendingAdapter implements HttpClientAdapter {
  final started = Completer<RequestOptions>();
  final response = Completer<ResponseBody>();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    started.complete(options);
    return response.future;
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _reply(Map<String, dynamic> data) => ResponseBody.fromString(
  jsonEncode({'status': 'Success', 'data': data}),
  200,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

Widget _screen(ServiceApi api) =>
    MaterialApp(home: PartnerServiceJobScreen(api: api, ar: false, id: 7));

void main() {
  test(
    'both job reads start immediately and every refresh reads again',
    () async {
      final api = _ControlledApi();
      addTearDown(api.close);
      final first = api.refreshJob(7);
      expect(api.jobReads, hasLength(1));
      expect(api.capabilitiesReads, hasLength(1));
      api.jobReads.first.complete(_job('First server response'));
      api.capabilitiesReads.first.complete(_ready);
      expect((await first).complete, isTrue);

      final second = api.refreshJob(7);
      expect(api.jobReads, hasLength(2));
      expect(api.capabilitiesReads, hasLength(2));
      api.capabilitiesReads.last.complete(
        const ServiceCapabilities(ready: true, enabled: false),
      );
      api.jobReads.last.complete(_job('Updated server response'));
      final refresh = await second;
      expect(refresh.job?['description'], 'Updated server response');
      expect(refresh.capabilities?.enabled, isFalse);
      expect(refresh.complete, isTrue);
    },
  );

  test(
    'a capabilities failure keeps the successful job read incomplete',
    () async {
      final api = _ControlledApi();
      addTearDown(api.close);
      final pending = api.refreshJob(7);
      api.jobReads.single.complete(_job('Latest server data'));
      api.capabilitiesReads.single.completeError(
        const ServiceFailure('Capabilities unavailable', 503),
      );
      final refresh = await pending;
      expect(refresh.job?['description'], 'Latest server data');
      expect(refresh.complete, isFalse);
      expect(refresh.error, isA<ServiceFailure>());
    },
  );

  test('a failed job read never becomes an actionable refresh', () async {
    final api = _ControlledApi();
    addTearDown(api.close);
    final pending = api.refreshJob(7);
    api.jobReads.single.completeError(
      const ServiceFailure('Job unavailable', 503),
    );
    api.capabilitiesReads.single.complete(_ready);
    final refresh = await pending;
    expect(refresh.job, isNull);
    expect(refresh.capabilities, same(_ready));
    expect(refresh.complete, isFalse);
  });

  test(
    'an account switch while capabilities is pending discards the job',
    () async {
      String? session = 'first-account';
      final api = _ControlledApi(token: () => session);
      addTearDown(api.close);
      final pending = api.refreshJob(7);
      api.jobReads.single.complete(_job('First account private data'));
      await Future<void>.delayed(Duration.zero);
      session = 'second-account';
      api.capabilitiesReads.single.complete(_ready);
      final refresh = await pending;
      expect(refresh.job, isNull);
      expect(refresh.capabilities, isNull);
      expect(
        refresh.error,
        isA<ServiceFailure>().having((e) => e.status, 'status', 401),
      );
    },
  );

  test(
    'a late mutation response cannot notify a different wallet session',
    () async {
      String? session = 'first-account';
      final adapter = _PendingAdapter();
      final api = ServiceApi(
        dio: Dio()..httpClientAdapter = adapter,
        baseUrl: 'https://example.invalid/api',
        token: () => session,
      );
      addTearDown(api.close);
      final walletRevision = goWalletChanges.value;
      final pending = api.skip(7);
      final sent = await adapter.started.future;
      expect(sent.headers['Authorization'], 'Bearer first-account');
      session = 'second-account';
      adapter.response.complete(_reply(_job('First account response')));
      await expectLater(
        pending,
        throwsA(isA<ServiceFailure>().having((e) => e.status, 'status', 401)),
      );
      expect(goWalletChanges.value, walletRevision);
    },
  );

  test('public capabilities remain usable after an account switch', () async {
    String? session = 'first-account';
    final adapter = _PendingAdapter();
    final api = ServiceApi(
      dio: Dio()..httpClientAdapter = adapter,
      baseUrl: 'https://example.invalid/api',
      token: () => session,
    );
    addTearDown(api.close);
    final pending = api.capabilities();
    final sent = await adapter.started.future;
    expect(sent.headers.containsKey('Authorization'), isFalse);
    session = null;
    adapter.response.complete(
      _reply({'schema_ready': true, 'version': 1, 'enabled': true}),
    );
    expect((await pending).ready, isTrue);
  });

  testWidgets(
    'two 300 ms reads display at 300 ms and periodic reads stay fresh',
    (tester) async {
      final api = _TimedApi();
      addTearDown(api.close);
      await tester.pumpWidget(_screen(api));
      expect(api.jobReads, 1);
      expect(api.capabilitiesReads, 1);
      await tester.pump(const Duration(milliseconds: 299));
      expect(find.text('Server refresh 1'), findsNothing);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(find.text('Server refresh 1'), findsOneWidget);

      await tester.pump(const Duration(seconds: 10));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(api.jobReads, 2);
      expect(api.capabilitiesReads, 2);
      expect(find.text('Server refresh 2'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final status in [401, 503]) {
    testWidgets(
      'new job data is shown but actions stay disabled when caps fail ($status)',
      (tester) async {
        final api = _ControlledApi();
        addTearDown(api.close);
        await tester.pumpWidget(_screen(api));
        api.jobReads.single.complete(_bookedJob('Latest server job'));
        api.capabilitiesReads.single.completeError(
          ServiceFailure('Capabilities unavailable', status),
        );
        await tester.pumpAndSettle();
        expect(find.text('Latest server job'), findsOneWidget);
        expect(find.text('Capabilities unavailable'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.widgetWithText(FilledButton, 'Start work'),
          200,
        );
        final start = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Start work'),
        );
        expect(start.onPressed, isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('an older refresh cannot replace a successful job action', (
    tester,
  ) async {
    final api = _ControlledApi()
      ..skippedJob = {
        ..._job('Action confirmed by server'),
        'status': 'cancelled',
      };
    addTearDown(api.close);
    await tester.pumpWidget(_screen(api));
    api.jobReads.single.complete(_job('Initial server data'));
    api.capabilitiesReads.single.complete(_ready);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));
    expect(api.jobReads, hasLength(2));
    expect(api.capabilitiesReads, hasLength(2));

    final skip = find.widgetWithText(OutlinedButton, 'Job is not for me');
    await tester.ensureVisible(skip);
    await tester.tap(skip);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect(api.skips, 1);
    expect(find.text('Action confirmed by server'), findsOneWidget);

    api.jobReads.last.complete(_job('Outdated in-flight response'));
    api.capabilitiesReads.last.complete(_ready);
    await tester.pumpAndSettle();
    expect(find.text('Action confirmed by server'), findsOneWidget);
    expect(find.text('Outdated in-flight response'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('expired sessions clear previously displayed job data', (
    tester,
  ) async {
    final api = _ControlledApi();
    addTearDown(api.close);
    await tester.pumpWidget(_screen(api));
    api.jobReads.single.complete(_bookedJob('Private account job'));
    api.capabilitiesReads.single.complete(_ready);
    await tester.pumpAndSettle();
    expect(find.text('Private account job'), findsOneWidget);

    await tester.pump(const Duration(seconds: 10));
    api.jobReads.last.completeError(
      const ServiceFailure('Please sign in', 401),
    );
    api.capabilitiesReads.last.complete(_ready);
    await tester.pumpAndSettle();
    expect(find.text('Private account job'), findsNothing);
    expect(find.text('Please sign in'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Start work'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
