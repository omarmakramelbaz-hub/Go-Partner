import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_partner/view/layout/order/widget/partner_price_offer_dialog.dart';

void main() {
  for (final ar in [true, false]) {
    for (final revision in [false, true]) {
      for (final submit in [true, false]) {
        testWidgets('price dialog ar=$ar revision=$revision submit=$submit survives reverse animation', (tester) async {
          num? result;
          var completed = false;
          await tester.pumpWidget(MaterialApp(home: StatefulBuilder(
            builder: (context, setState) => Scaffold(body: Column(children: [
              Text(completed ? 'returned' : 'waiting'),
              FilledButton(key: const ValueKey('open-price-dialog'), onPressed: () async {
                result = await showDialog<num>(context: context, builder: (_) => PartnerPriceOfferDialog(
                  initialPrice: '35', ar: ar, revision: revision,
                ));
                if (context.mounted) setState(() => completed = true);
              }, child: const Text('Open')),
            ])),
          )));
          await tester.tap(find.byKey(const ValueKey('open-price-dialog')));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), ar ? '٣٥٫٥' : '35.5');
          await tester.tap(find.byKey(ValueKey(submit ? 'partner-offer-submit' : 'partner-offer-cancel')));
          // Pop has resolved, but the route still builds during the reverse
          // transition. This is the lifecycle that crashed both courier tests.
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 30));
          expect(tester.takeException(), isNull);
          await tester.pumpAndSettle();
          expect(completed, isTrue);
          expect(result, submit ? 35.5 : null);
          expect(find.byType(PartnerPriceOfferDialog), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }

  testWidgets('invalid and non-finite prices do not close the dialog', (tester) async {
    num? result;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(
      body: FilledButton(onPressed: () async {
        result = await showDialog<num>(context: context, builder: (_) => const PartnerPriceOfferDialog(initialPrice: '', ar: false));
      }, child: const Text('Open')),
    ))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    for (final invalid in ['', '0', '-1', 'NaN', 'Infinity', '-Infinity', 'not a price']) {
      await tester.enterText(find.byType(TextField), invalid);
      await tester.tap(find.byKey(const ValueKey('partner-offer-submit')));
      await tester.pump();
      expect(find.byType(PartnerPriceOfferDialog), findsOneWidget);
      expect(find.text('Enter a valid price above zero'), findsOneWidget);
      expect(result, isNull);
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.byKey(const ValueKey('partner-offer-cancel')));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
