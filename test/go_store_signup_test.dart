import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import '../lib/go_store_signup/store_signup_draft.dart';
import '../lib/go_store_signup/store_signup_screen.dart';

final pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAIAAAAlC+aJAAAAYUlEQVR4nO3PQQkAIADAQDWy/QVD+DiEXYJtnj3Hz5YOeNWA1oDWgNaA1oDWgNaA1oDWgNaA1oDWgNaA1oDWgNaA1oDWgNaA1oDWgNaA1oDWgNaA1oDWgNaA1oDWgNaAdgGfGwHwXwv+JAAAAABJRU5ErkJggg==',
);
StoreSignupDraft draft() => StoreSignupDraft()
  ..name = 'ماركت المدينة'
  ..kind = 'supermarket'
  ..address = 'شارع النيل، المنصورة'
  ..logo = SignupImage(pixel, 'png')
  ..products.add(
    SignupProduct(
      name: 'أرز مصري',
      unit: 'كيلو',
      price: '80.50',
      image: SignupImage(pixel, 'png'),
      options: [
        {'label': 'نصف كيلو', 'price': '42.75'},
        {'label': 'ربع كيلو', 'price': '23.25'},
      ],
    ),
  );

class CaptureAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int? failBatch;
  bool failed = false;
  int batches = 0;
  bool rejectSession = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.path.endsWith('/catalog-images')) {
      batches++;
      if (batches == failBatch && !failed) {
        failed = true;
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      }
    }
    if (rejectSession && options.path.endsWith('/catalog-images')) {
      return ResponseBody.fromString(
        jsonEncode({
          'errors': {
            'catalog_upload_token': ['انتهت الجلسة'],
          },
        }),
        422,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({
        'status': 'Success',
        'data': options.path.endsWith('/catalog-upload')
            ? {'upload_token': 'fixture-upload-token', 'expires_in': 7200}
            : {'application_id': 23},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<void> revealProductSave(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
  final button = find.text('حفظ المنتج في الطلب');
  for (var i = 0; i < 20 && button.hitTestable().evaluate().isEmpty; i++) {
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -250),
    );
    await tester.pumpAndSettle();
  }
  expect(button.hitTestable(), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Tajawal')
          ..addFont(rootBundle.load('assets/font/Tajawal/Tajawal-Regular.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  test('prices and required store fields are checked before signup', () {
    expect(signupPrice('٤٢٫٧٥'), '42.75');
    for (final value in ['-1', '0', '1.234', '1e2', '1000000.01']) {
      expect(signupPrice(value), isNull);
    }
    final store = StoreSignupDraft();
    expect(store.validate(), isNotNull);
    expect(draft().validate(), isNull);
  });
  test(
    '60 products use small batches and a metadata-only final catalog',
    () async {
      final adapter = CaptureAdapter();
      final api = PartnerApplicationApi(
        client: Dio()..httpClientAdapter = adapter,
        scope: 'go',
      );
      final store = draft();
      final first = store.products.single;
      store.products.addAll(
        List.generate(
          59,
          (i) => SignupProduct(
            name: 'منتج ${i + 1}',
            unit: 'كيلو',
            price: '${i + 1}.00',
            image: SignupImage(pixel, 'png'),
          ),
        ),
      );
      expect(store.validate(), isNull);
      store.products.add(first);
      expect(store.validate(), isNotNull);
      store.products.removeLast();
      final progress = <String>[];
      store.progress.addListener(() {
        if (store.progress.value != null) progress.add(store.progress.value!);
      });
      await api.submit(
        {
          'mobile': '01012345678',
          'email': 'owner@example.com',
          'email_verification_token': 'proof',
        },
        XFile.fromData(pixel, name: 'portrait.png'),
        store: store,
      );
      final uploads = adapter.requests
          .where((r) => r.path.endsWith('/catalog-images'))
          .toList();
      expect(uploads.length, 13);
      final slots = <String>[];
      for (final request in uploads) {
        expect(request.headers['X-App-Scope'], 'go');
        expect(request.headers.containsKey('Authorization'), isFalse);
        final data = request.data as FormData;
        expect(data.files.length, lessThanOrEqualTo(5));
        slots.addAll(data.files.map((e) => e.key));
      }
      expect(slots, [
        'images[logo]',
        for (var i = 0; i < 60; i++) 'images[p$i]',
      ]);
      final body = adapter.requests.last.data as FormData;
      expect(body.files.map((e) => e.key), ['photo']);
      final fields = Map.fromEntries(body.fields);
      expect(fields.containsKey('email_verification_token'), isFalse);
      expect(fields['catalog_upload_token'], 'fixture-upload-token');
      final catalog = jsonDecode(fields['storefront']!);
      expect(catalog['products'].length, 60);
      expect(catalog['products'][0]['options'][0]['price'], '42.75');
      expect(progress, contains('جارٍ رفع الصور: 60 من 61'));
      expect(store.progress.value, isNull);
      api.close();
    },
  );

  test(
    'interrupted uploads resume with fresh bodies and only changed image slots',
    () async {
      final adapter = CaptureAdapter()..failBatch = 2;
      final api = PartnerApplicationApi(
        client: Dio()..httpClientAdapter = adapter,
      );
      final store = draft();
      store.products.addAll(
        List.generate(
          6,
          (i) => SignupProduct(
            name: 'منتج $i',
            unit: 'كيلو',
            price: '10',
            image: SignupImage(pixel, 'png'),
          ),
        ),
      );
      final fields = {
        'mobile': '01012345678',
        'email': 'owner@example.com',
        'email_verification_token': 'proof',
      };
      final photo = XFile.fromData(pixel, name: 'portrait.png');
      await expectLater(
        api.submit(fields, photo, store: store),
        throwsA(isA<StoreSignupFailure>()),
      );
      expect(
        store.hasUploadSession('01012345678', 'owner@example.com'),
        isTrue,
      );
      expect(
        store.hasUploadSession('01099999999', 'owner@example.com'),
        isFalse,
      );
      final failedBody = adapter.requests.last.data;
      await api.submit(fields, photo, store: store);
      expect(
        adapter.requests
            .where((r) => r.path.endsWith('/catalog-upload'))
            .length,
        1,
      );
      final batches = adapter.requests
          .where((r) => r.path.endsWith('/catalog-images'))
          .toList();
      expect(batches.length, 3);
      expect(identical(failedBody, batches.last.data), isFalse);
      expect((batches.last.data as FormData).files.map((e) => e.key), [
        'images[p4]',
        'images[p5]',
        'images[p6]',
      ]);
      store.logo = SignupImage(pixel, 'png');
      await api.submit(fields, photo, store: store);
      final changed =
          adapter.requests
                  .where((r) => r.path.endsWith('/catalog-images'))
                  .last
                  .data
              as FormData;
      expect(changed.files.map((e) => e.key), ['images[logo]']);
      api.close();
    },
  );

  test('expired upload sessions require email verification again and retain products', () async {
    final adapter = CaptureAdapter()..rejectSession = true;
    final api = PartnerApplicationApi(
      client: Dio()..httpClientAdapter = adapter,
    );
    final store = draft();
    await expectLater(
      api.submit(
        {
          'mobile': '01012345678',
          'email': 'owner@example.com',
          'email_verification_token': 'proof',
        },
        XFile.fromData(pixel, name: 'portrait.png'),
        store: store,
      ),
      throwsA(isA<StoreSignupFailure>()),
    );
    expect(store.hasUploadSession('01012345678', 'owner@example.com'), isFalse);
    expect(store.products.length, 1);
    api.close();
  });
  testWidgets(
    'second step preserves edits and products after a failed submission',
    (tester) async {
      final store = draft();
      var submissions = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Tajawal'),
          home: StoreSignupScreen(
            draft: store,
            onSubmit: () async {
              submissions++;
              throw const StoreSignupFailure('تعذر الاتصال، حاول مرة أخرى');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final name = find.widgetWithText(TextFormField, 'اسم المتجر');
      await tester.enterText(name, 'متجر جديد');
      await tester.tap(find.text('تأكيد البريد وإرسال الطلب'));
      await tester.pumpAndSettle();
      expect(submissions, 1);
      expect(store.name, 'متجر جديد');
      expect(store.products.single.name, 'أرز مصري');
      expect(find.text('تأكيد البريد وإرسال الطلب'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('product editor keeps weight options and image while editing', (
    tester,
  ) async {
    final store = draft();
    SignupProduct? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                saved = await Navigator.push<SignupProduct>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SignupProductScreen(product: store.products.single),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final price = find.widgetWithText(TextFormField, 'السعر بالجنيه');
    await tester.ensureVisible(price);
    await tester.enterText(price, '0');
    await revealProductSave(tester);
    await tester.tap(find.text('حفظ المنتج في الطلب'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    expect(
      find.text('اكتب سعرًا صحيحًا من 0.01 إلى 1000000 ج'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(price);
    await tester.pumpAndSettle();
    await tester.enterText(price, '٩٠٫٢٥');
    await revealProductSave(tester);
    await tester.tap(find.text('حفظ المنتج في الطلب').hitTestable());
    await tester.pumpAndSettle();
    expect(saved!.price, '90.25');
    expect(saved!.options[1]['price'], '23.25');
    expect(saved!.image, store.products.single.image);
    expect(tester.takeException(), isNull);
  });
  testWidgets('store signup layout fits a phone and renders review preview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Tajawal'),
        home: RepaintBoundary(
          key: boundary,
          child: StoreSignupScreen(draft: draft(), onSubmit: () async => false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('٢ من ٢ • المتجر والمنتجات'), findsOneWidget);
    expect(find.text('أرز مصري'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final image =
          await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory =
          Platform.environment['GO_STORE_SCREENSHOTS'] ?? 'build/ui-preview';
      await Directory(directory).create(recursive: true);
      await File('$directory/store-signup.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
