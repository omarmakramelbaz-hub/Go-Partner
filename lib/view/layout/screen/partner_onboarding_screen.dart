import 'package:flutter/material.dart';
import '../../../helpers/identity/partner_app_identity.dart';
import '../../../helpers/utils/navigator_methods.dart';
import '../auth/screen/login_screen.dart';

class PartnerOnboardingScreen extends StatelessWidget {
  const PartnerOnboardingScreen({super.key});
  static const String routeName = 'PartnerOnboardingScreen';
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff101216),
    body: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            PartnerAppIdentity.welcomeBackgroundAsset,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xe6101216),
                  Color(0xff101216),
                ],
                stops: [0, .45, .75, 1],
              ),
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 24, 26, 26),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 50,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      SizedBox(height: constraints.maxHeight * .5),
                      const Text(
                        'انضم كشريك في GO',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          height: 1.3,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'اختر مجالك، وابدأ رحلتك معنا',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xffd3d6dc),
                          fontSize: 17,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 56,
                        child: FilledButton(
                          onPressed: () =>
                              NavigatorMethods.pushNamedAndRemoveUntil(
                                context,
                                LoginScreen.routeName,
                              ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xfffd7201),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'ابدأ الآن',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'معًا نصنع الفرص',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xffa9afb8)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
