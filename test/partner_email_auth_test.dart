import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_partner/helpers/networking/partner_email_auth.dart';
import 'package:go_partner/view/layout/auth/screen/partner_email_verification_screen.dart';

class FakeEmailAuth extends PartnerEmailAuth {
  int sends = 0;
  String? submittedCode;
  bool reject = false;
  @override
  Future<PartnerEmailChallenge> requestCode({
    required String purpose,
    required String mobile,
    String? email,
  }) async {
    sends++;
    return const PartnerEmailChallenge('server-challenge', 60);
  }

  @override
  Future<String> verify(String challengeId, String code) async {
    submittedCode = code;
    if (reject)
      throw const PartnerAuthFailure('الكود غير صحيح أو انتهت صلاحيته.');
    return 'verified-server-proof';
  }
}

void main() {
  testWidgets(
    'email flow blocks short codes, uses server verification, and returns the proof',
    (tester) async {
      final api = FakeEmailAuth();
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PartnerEmailVerificationScreen(
                        mobile: '01012345678',
                        purpose: 'application',
                        email: 'partner@gmail.com',
                        api: api,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(api.sends, 1);
      await tester.enterText(find.byType(TextField), '1234');
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'تأكيد البريد'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'تأكيد البريد'));
      await tester.pump();
      expect(api.submittedCode, isNull);
      expect(result, isNull);
      await tester.enterText(find.byType(TextField), '123456');
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'تأكيد البريد'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'تأكيد البريد'));
      await tester.pumpAndSettle();
      expect(api.submittedCode, '123456');
      expect(result, 'verified-server-proof');
    },
  );

  testWidgets(
    'wrong server code stays on screen and resend is disabled during cooldown',
    (tester) async {
      final api = FakeEmailAuth()..reject = true;
      await tester.pumpWidget(
        MaterialApp(
          home: PartnerEmailVerificationScreen(
            mobile: '01012345678',
            purpose: 'password_reset',
            api: api,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '654321');
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'تأكيد البريد'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'تأكيد البريد'));
      await tester.pumpAndSettle();
      expect(find.text('الكود غير صحيح أو انتهت صلاحيته.'), findsOneWidget);
      final resend = tester.widget<TextButton>(find.byType(TextButton));
      expect(resend.onPressed, isNull);
      expect(api.sends, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('verification form stays usable on a small Arabic phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: PartnerEmailVerificationScreen(
          mobile: '01012345678',
          purpose: 'application',
          email: 'partner@gmail.com',
          api: FakeEmailAuth(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'تأكيد البريد'),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
