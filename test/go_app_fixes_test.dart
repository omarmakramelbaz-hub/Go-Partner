import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../lib/helpers/hive/hive_methods.dart';
import '../lib/helpers/theme/app_theme_controller.dart';
import '../lib/view/layout/auth/bottom_sheet/change_lang_bottom_sheet.dart';
import '../lib/view/layout/my_account/controller/my_account_controller.dart';
import '../lib/view/layout/my_account/model/setting_model.dart';
import '../lib/view/layout/wallet/controller/wallet_controller.dart';
import '../lib/view/layout/wallet/widget/chooseVCashOrVisaWidget.dart';

class PaymentSettings extends MyAccountController {
  @override
  SettingModel get setting =>
      SettingModel(walletCardActivate: 'true', paymentCardActivate: 'true');
}

class Words extends AssetLoader {
  const Words();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('i18n/${locale.languageCode}.json').readAsStringSync()),
      );
}

Widget app(Widget child, String language) => EasyLocalization(
  supportedLocales: const [Locale('ar'), Locale('en')],
  startLocale: Locale(language),
  saveLocale: false,
  path: 'i18n',
  assetLoader: const Words(),
  child: Builder(
    builder: (context) => MaterialApp(
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: child,
    ),
  ),
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    directory = await Directory.systemTemp.createTemp('go-partner-fixes');
    Hive.init(directory.path);
    await Hive.openBox('app');
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });
  test('English covers every Arabic key without Arabic placeholder values', () {
    final ar = jsonDecode(File('i18n/ar.json').readAsStringSync()) as Map;
    final en = jsonDecode(File('i18n/en.json').readAsStringSync()) as Map;
    expect(ar.keys.where((key) => !en.containsKey(key)), isEmpty);
    expect(
      en.values.where((value) => RegExp(r'[\u0600-\u06FF]').hasMatch('$value')),
      isEmpty,
    );
  });
  for (final language in ['ar', 'en']) {
    testWidgets(
      'language selector changes direction and persists choice from $language',
      (tester) async {
        final next = language == 'ar' ? 'en' : 'ar';
        await tester.pumpWidget(
          app(
            Builder(
              builder: (context) => Scaffold(
                body: Column(
                  children: [
                    Text(
                      context.locale.languageCode,
                      key: const ValueKey('language'),
                    ),
                    TextButton(
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        builder: (_) => const ChangeLangBottomSheet(),
                      ),
                      child: const Text('open'),
                    ),
                  ],
                ),
              ),
            ),
            language,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.text('English'), findsOneWidget);
        expect(find.text('العربية'), findsOneWidget);
        await tester.tap(find.text(next == 'en' ? 'English' : 'العربية'));
        await tester.pumpAndSettle();
        expect(HiveMethods.getLang(), next);
        expect(
          tester.widget<Text>(find.byKey(const ValueKey('language'))).data,
          next,
        );
        expect(
          Directionality.of(
            tester.element(find.byKey(const ValueKey('language'))),
          ),
          next == 'ar' ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        );
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('top-up offers wallets and cards only in $language', (
      tester,
    ) async {
      final wallet = WalletController();
      final settings = PaymentSettings();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppThemeController()),
            ChangeNotifierProvider<WalletController>.value(value: wallet),
            ChangeNotifierProvider<MyAccountController>.value(value: settings),
          ],
          child: app(
            Scaffold(
              body: ChooseVCashOrVisaWidget(myAccountController: settings),
            ),
            language,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final cards = find.text(language == 'ar' ? 'بطاقات بنكية' : 'Bank cards');
      final wallets = find.text(
        language == 'ar' ? 'محافظ إلكترونية' : 'Electronic wallets',
      );
      expect(cards, findsOneWidget);
      expect(wallets, findsOneWidget);
      expect(find.text('Apple Pay'), findsNothing);
      expect(find.text('Google Pay'), findsNothing);
      await tester.tap(cards);
      await tester.pump();
      expect(wallet.selectedPayment, 'online');
      await tester.tap(wallets);
      await tester.pump();
      expect(wallet.selectedPayment, 'v_cash');
      wallet.setSelectedPayment('apple_pay');
      expect(wallet.selectedPayment, 'v_cash');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      wallet.dispose();
      settings.dispose();
    });
  }
}
