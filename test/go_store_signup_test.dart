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
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({
        'status': 'Success',
        'data': {'application_id': 23},
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
  test('multipart catalog ties each image to its product and uses fresh data on retry', () async {
    final adapter = CaptureAdapter();
    final client = Dio()..httpClientAdapter = adapter;
    final api = PartnerApplicationApi(client: client, scope: 'go');
    final photo = XFile.fromData(pixel, name: 'portrait.png');
    for (var i = 0; i < 2; i++) {
      await api.submit(
        {'mobile': '01012345678', 'email_verification_token': 'fixture-proof'},
        photo,
        store: draft(),
      );
    }
    final request = adapter.requests.first;
    expect(request.headers['X-App-Scope'], 'go');
    expect(request.headers.containsKey('Authorization'), isFalse);
    final body = request.data as FormData;
    expect(body.files.map((e) => e.key), [
      'photo',
      'store_logo',
      'product_images[0]',
    ]);
    final store = jsonDecode(
      body.fields.firstWhere((e) => e.key == 'storefront').value,
    );
    expect(store['products'][0]['options'][0]['price'], '42.75');
    expect(store.containsKey('user_id'), isFalse);
    expect(identical(body, adapter.requests.last.data), isFalse);
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
    await tester.enterText(price, '٩٠٫٢٥');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final save = find.text('حفظ المنتج في الطلب');
    await tester.scrollUntilVisible(
      save,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
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
