import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../lib/go_services/service_api.dart';
import '../lib/go_stores/store_api.dart';
import '../lib/go_stores/store_catalog.dart';
import '../lib/go_stores/store_product_editor.dart';
import '../lib/view/layout/auth/model/profile_model.dart';

class _Translations extends AssetLoader {
  const _Translations();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {};
}

Widget harness(Widget child, [String language = 'ar']) => EasyLocalization(
  supportedLocales: const [Locale('ar'), Locale('en')],
  startLocale: Locale(language),
  saveLocale: false,
  path: 'i18n',
  assetLoader: const _Translations(),
  child: Builder(
    builder: (context) => MaterialApp(
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Tajawal'),
      home: child,
    ),
  ),
);

Map<String, dynamic> product() => {
  'id': 4,
  'name': 'أرز مصري',
  'description': 'أرز أبيض عالي الجودة',
  'unit': 'كيلو',
  'price': '80.50',
  'image_url': 'https://example.test/rice.png',
  'revision': 3,
  'available': true,
  'options': [
    {
      'id': '00000000-0000-4000-8000-000000000001',
      'label': 'نصف كيلو',
      'price': '42.75',
    },
  ],
};

class FakeStoreApi extends StoreApi {
  final saves = <Map<String, dynamic>>[];
  bool fail = false;
  @override
  Future<Map<String, dynamic>> catalog({
    int page = 1,
    String search = '',
  }) async => {
    'store': {
      'name': 'ماركت المدينة',
      'kind': 'supermarket',
      'address': 'شارع النيل، القاهرة',
      'revision': 1,
    },
    'products': [product()],
    'page': 1,
    'last_page': 1,
    'total': 1,
  };
  @override
  Future<Map<String, dynamic>> saveProduct(
    Map<String, dynamic> value, {
    int? id,
    XFile? image,
  }) async {
    saves.add({...value, 'id': id, 'has_image': image != null});
    if (fail) throw const ServiceFailure('Connection failed');
    return {
      'product': {...value, 'id': id ?? 4},
    };
  }
}

class _Adapter implements HttpClientAdapter {
  RequestOptions? request;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    request = options;
    return ResponseBody.fromString(
      '{"status":"Success","data":{"product":{"id":4}}}',
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
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await (FontLoader('Tajawal')
          ..addFont(rootBundle.load('assets/font/Tajawal/Tajawal-Regular.ttf'))
          ..addFont(rootBundle.load('assets/font/Tajawal/Tajawal-Bold.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  test('store prices preserve decimal cents and normalize Arabic digits', () {
    expect(storePrice('٤٢٫٧٥'), '42.75');
    expect(storePrice('0.01'), '0.01');
    expect(storePrice('1000000'), '1000000.00');
    for (final value in ['-1', '0', '1.001', '1e2', '1000000.01']) {
      expect(storePrice(value), isNull);
    }
    expect(
      ProfileModel(accountType: 'vendor', appScope: 'go_partner').isGoStore,
      isTrue,
    );
    expect(
      ProfileModel(
        accountType: 'delegate',
        appScope: 'go_partner',
        partnerProfessionKey: 'store_owner',
      ).isGoStore,
      isTrue,
    );
    expect(
      ProfileModel(accountType: 'vendor', appScope: 'fasakhansta').isGoStore,
      isFalse,
    );
    expect(
      ProfileModel(
        accountType: 'delegate',
        appScope: 'go_partner',
        partnerProfessionKey: 'plumber',
      ).isGoStore,
      isFalse,
    );
  });

  test('multipart product API sends authenticated scope, option JSON and image bytes', () async {
    final adapter = _Adapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final api = StoreApi(
      dio: dio,
      baseUrl: 'https://example.test/api',
      token: () => 'test-token',
    );
    await api.saveProduct(
      {
        'name': 'Rice',
        'available': true,
        'options': [
          {'label': 'Half kilo', 'price': '42.75'},
        ],
      },
      image: XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        name: 'rice.png',
        path: 'rice.png',
      ),
    );
    expect(
      adapter.request!.path,
      'https://example.test/api/go-stores/products',
    );
    expect(adapter.request!.headers['X-App-Scope'], 'go_partner');
    expect(adapter.request!.headers['Authorization'], 'Bearer test-token');
    final body = adapter.request!.data as FormData;
    expect(Map.fromEntries(body.fields)['available'], '1');
    expect(
      jsonDecode(Map.fromEntries(body.fields)['options']!)[0]['price'],
      '42.75',
    );
    expect(body.files.single.value.filename, 'rice.png');
    api.close();
  });

  for (final language in ['ar', 'en']) {
    final ar = language == 'ar';
    testWidgets('store catalog and editor fit mobile in $language', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = FakeStoreApi();
      final boundary = GlobalKey();
      await tester.pumpWidget(
        harness(
          RepaintBoundary(
            key: boundary,
            child: StoreCatalog(api: api),
          ),
          language,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ماركت المدينة'), findsOneWidget);
      expect(find.text(ar ? 'إضافة منتج' : 'Add product'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final output = Platform.environment['GO_STORE_SCREENSHOTS'];
      if (output != null) {
        final render =
            boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(output).create(recursive: true);
          await File('$output/catalog-$language.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
      api.close();
    });

    testWidgets(
      'editing options preserves ids, explicit prices and retry key in $language',
      (tester) async {
        final api = FakeStoreApi()..fail = true;
        await tester.pumpWidget(
          harness(StoreProductEditor(api: api, product: product()), language),
        );
        await tester.pumpAndSettle();
        final chip = find.widgetWithText(
          ActionChip,
          ar ? '+ ربع كيلو' : '+ Quarter kilo',
        );
        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.pumpAndSettle();
        final optionFields = find.widgetWithText(
          TextFormField,
          ar ? 'سعر الاختيار بالجنيه' : 'Option price in EGP',
        );
        await tester.ensureVisible(optionFields.last);
        await tester.enterText(optionFields.last, '٢٣٫٢٥');
        final save = find.widgetWithText(
          FilledButton,
          ar ? 'حفظ المنتج' : 'Save product',
        );
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(api.saves, hasLength(1));
        expect(api.saves.single['revision'], 3);
        expect(
          api.saves.single['options'][0]['id'],
          '00000000-0000-4000-8000-000000000001',
        );
        expect(api.saves.single['options'][0]['price'], '42.75');
        expect(api.saves.single['options'][1]['price'], '23.25');
        expect(api.saves.single['has_image'], isFalse);
        expect(find.text('Connection failed'), findsOneWidget);
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(api.saves, hasLength(2));
        expect(api.saves.first['request_key'], api.saves.last['request_key']);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        api.close();
      },
    );
  }
}
