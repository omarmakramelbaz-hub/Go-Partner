import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/view/custom_widgets/popups/go_popups.dart';
import '../lib/view/custom_widgets/custom_toast/custom_toast.dart';
import '../lib/view/layout/wallet/widget/wallet_transfer_view.dart';
import '../lib/view/layout/wallet/widget/wallet_charge_view.dart';
import '../lib/view/layout/wallet/model/wallet_transfer.dart';

late Map<String, String> words;
String t(String key) => words[key] ?? key;

Future<void> screenshot(WidgetTester tester, GlobalKey key, String name) async {
  final render =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await render.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/ui-preview/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Widget app({
  required bool ar,
  required WidgetBuilder builder,
  double scale = 1,
  GlobalKey? boundary,
}) => MaterialApp(
  locale: Locale(ar ? 'ar' : 'en'),
  supportedLocales: const [Locale('ar'), Locale('en')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  theme: ThemeData(fontFamily: 'Tajawal'),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: RepaintBoundary(key: boundary, child: child!),
  ),
  home: Builder(builder: builder),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Tajawal')
          ..addFont(rootBundle.load('assets/font/Tajawal/Tajawal-Regular.ttf'))
          ..addFont(rootBundle.load('assets/font/Tajawal/Tajawal-Bold.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final ar in [true, false]) {
    for (final width in [320.0, 390.0, 900.0]) {
      testWidgets(
        'transfer destinations, validation and keyboard fit: $width ar=$ar',
        (tester) async {
          words = Map<String, String>.from(
            jsonDecode(
              File('i18n/${ar ? 'ar' : 'en'}.json').readAsStringSync(),
            ),
          );
          await tester.binding.setSurfaceSize(Size(width, 850));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final phone = TextEditingController(),
              amount = TextEditingController();
          final focus = FocusNode(),
              form = GlobalKey<FormState>(),
              boundary = GlobalKey();
          TransferWallet? selected;
          var reviews = 0, edits = 0;
          await tester.pumpWidget(
            app(
              ar: ar,
              scale: width == 320 ? 1.6 : 1,
              boundary: boundary,
              builder: (context) => Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () => showGoModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => StatefulBuilder(
                        builder: (context, setState) => WalletTransferSheetView(
                          translate: t,
                          formKey: form,
                          mobileController: phone,
                          amountController: amount,
                          amountFocusNode: focus,
                          selectedWallet: selected,
                          onWalletChanged: (value) =>
                              setState(() => selected = value),
                          onDetailsChanged: (_) => edits++,
                          validatePhone: (value) =>
                              value?.length == 11 ? null : 'phone error',
                          validateAmount: (value) =>
                              (num.tryParse(value ?? '') ?? 0) >= 1
                              ? null
                              : 'amount error',
                          onReview: () {
                            if (form.currentState!.validate()) reviews++;
                          },
                          onClose: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(selected, isNull);
          for (final wallet in TransferWallet.values)
            expect(
              find.byKey(ValueKey('wallet-choice-${wallet.value}')),
              findsOneWidget,
            );
          final review = find.byKey(const ValueKey('wallet-transfer-review'));
          await tester.ensureVisible(review);
          await tester.tap(review);
          await tester.pumpAndSettle();
          expect(reviews, 0);
          expect(find.text(t('chooseRecipientWallet')), findsOneWidget);
          final choice = find.byKey(const ValueKey('wallet-choice-go_partner'));
          await tester.ensureVisible(choice);
          await tester.tap(choice);
          await tester.pumpAndSettle();
          expect(selected, TransferWallet.goPartner);
          final phoneField = find.byKey(
            const ValueKey('wallet-transfer-phone'),
          );
          final amountField = find.byKey(
            const ValueKey('wallet-transfer-amount'),
          );
          await tester.ensureVisible(phoneField);
          await tester.enterText(phoneField, '01012345678');
          await tester.ensureVisible(amountField);
          await tester.enterText(amountField, '150');
          tester.testTextInput.hide();
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          await tester.ensureVisible(review);
          await tester.tap(review);
          await tester.pumpAndSettle();
          expect(reviews, 1);
          expect(edits, 2);
          expect(tester.takeException(), isNull);
          if (width == 390 && ar) {
            await tester.drag(
              find.byType(SingleChildScrollView).first,
              const Offset(0, 1000),
            );
            await tester.pumpAndSettle();
            await screenshot(tester, boundary, 'transfer-ar');
          }
          // The real OS keyboard leaves the action reachable through scrolling.
          tester.view.viewInsets = const FakeViewPadding(bottom: 280);
          await tester.pumpAndSettle();
          await tester.ensureVisible(review);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(tester.getRect(review).bottom, lessThanOrEqualTo(851));
          tester.view.resetViewInsets();
          await tester.pumpAndSettle();
          await tester.pumpWidget(const SizedBox());
          phone.dispose();
          amount.dispose();
          focus.dispose();
        },
      );
    }
  }

  testWidgets(
    'top-up shares the shell and keeps amount validation and payment choices',
    (tester) async {
      words = Map<String, String>.from(
        jsonDecode(File('i18n/ar.json').readAsStringSync()),
      );
      await tester.binding.setSurfaceSize(const Size(390, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final boundary = GlobalKey(), form = GlobalKey<FormState>();
      final amount = TextEditingController(), focus = FocusNode();
      var paid = 0;
      String? selected;
      await tester.pumpWidget(
        app(
          ar: true,
          boundary: boundary,
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showGoModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => StatefulBuilder(
                    builder: (context, setState) => WalletChargeSheetView(
                      translate: t,
                      formKey: form,
                      amountController: amount,
                      amountFocusNode: focus,
                      validator: (value) =>
                          (num.tryParse(value ?? '') ?? 0) >= 50
                          ? null
                          : 'minimum 50',
                      paymentMethods: Column(
                        children: [
                          for (final method in ['محفظة إلكترونية', 'كارت بنكي'])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GoPopupChoice(
                                label: method,
                                selected: selected == method,
                                leading: const Icon(
                                  Icons.account_balance_wallet_outlined,
                                ),
                                onTap: () => setState(() => selected = method),
                              ),
                            ),
                        ],
                      ),
                      onPay: () {
                        if (form.currentState!.validate() && selected != null)
                          paid++;
                      },
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('wallet-charge-pay')));
      await tester.pumpAndSettle();
      expect(paid, 0);
      expect(find.text('minimum 50'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('wallet-charge-amount')),
        '100',
      );
      await tester.tap(find.text('كارت بنكي'));
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await screenshot(tester, boundary, 'charge-ar');
      await tester.tap(find.byKey(const ValueKey('wallet-charge-pay')));
      expect(paid, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      amount.dispose();
      focus.dispose();
    },
  );

  for (final confirmed in [false, true]) {
    testWidgets(
      'confirmation returns the selected action and fits large text: $confirmed',
      (tester) async {
        words = Map<String, String>.from(
          jsonDecode(File('i18n/ar.json').readAsStringSync()),
        );
        await tester.binding.setSurfaceSize(const Size(320, 720));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        bool? result;
        await tester.pumpWidget(
          app(
            ar: true,
            scale: 1.6,
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () async {
                  result = await showGoDialog<bool>(
                    context: context,
                    builder: (_) => WalletTransferReviewDialog(
                      translate: t,
                      preview: const WalletTransferPreview(
                        wallet: TransferWallet.goPartner,
                        mobile: '01012345678',
                        amount: 150,
                        recipientId: 10,
                        recipientName:
                            'اسم مستلم طويل لاختبار العرض على شاشة صغيرة',
                        token: 'test-only',
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final action = find.byKey(
          ValueKey(
            confirmed ? 'wallet-transfer-confirm' : 'wallet-transfer-edit',
          ),
        );
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(result, confirmed);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'shared alert, picker and toast have readable content and working actions',
    (tester) async {
      final boundary = GlobalKey();
      await tester.binding.setSurfaceSize(const Size(390, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      bool? result;
      var chosen = false;
      await tester.pumpWidget(
        app(
          ar: true,
          boundary: boundary,
          builder: (context) => Scaffold(
            body: Column(
              children: [
                FilledButton(
                  onPressed: () async {
                    result = await showGoDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('تأكيد الإجراء'),
                        content: const Text('راجع البيانات قبل المتابعة.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('رجوع'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('تأكيد'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Dialog'),
                ),
                FilledButton(
                  onPressed: () => showGoModalBottomSheet<void>(
                    context: context,
                    builder: (c) => GoSheet(
                      title: 'إضافة صورة',
                      icon: Icons.add_photo_alternate_outlined,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          chosen = true;
                          Navigator.pop(c);
                        },
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('معرض الصور'),
                      ),
                    ),
                  ),
                  child: const Text('Sheet'),
                ),
                const CustomToast(
                  type: ToastType.success,
                  message: 'تم حفظ بياناتك بنجاح',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Dialog'));
      await tester.pumpAndSettle();
      await screenshot(tester, boundary, 'confirmation-ar');
      await tester.tap(find.text('تأكيد'));
      await tester.pumpAndSettle();
      expect(result, true);
      await tester.tap(find.text('Sheet'));
      await tester.pumpAndSettle();
      await screenshot(tester, boundary, 'photo-picker-ar');
      await tester.tap(find.text('معرض الصور'));
      await tester.pumpAndSettle();
      expect(chosen, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
