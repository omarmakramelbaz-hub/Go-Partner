import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../helpers/utils/navigator_methods.dart';
import '../../auth/screen/login_screen.dart';

class PartnerOnboardingScreen extends StatelessWidget {
  const PartnerOnboardingScreen({super.key});

  static const String routeName = 'PartnerOnboardingScreen';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff171A1F),
      body: Stack(
        children: [
          const Positioned.fill(child: _OnboardingBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
              child: Column(
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SvgPicture.asset(
                      'assets/svg/go_partner_logo.svg',
                      width: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      color: const Color(0xffFD7201).withOpacity(.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xffFD7201).withOpacity(.28)),
                    ),
                    child: const Icon(Icons.handshake_rounded, size: 86, color: Color(0xffFD7201)),
                  ),
                  const SizedBox(height: 34),
                  const Text(
                    'انضم كشريك في GO',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 30, height: 1.2, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'اختر مجالك، استقبل الطلبات المناسبة لك، وابدأ رحلتك معنا',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(.72), fontSize: 16, height: 1.65, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 22, height: 7, decoration: BoxDecoration(color: const Color(0xffFD7201), borderRadius: BorderRadius.circular(10))),
                      const SizedBox(width: 6),
                      Container(width: 7, height: 7, decoration: BoxDecoration(color: Colors.white.withOpacity(.28), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Container(width: 7, height: 7, decoration: BoxDecoration(color: Colors.white.withOpacity(.28), shape: BoxShape.circle)),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: FilledButton(
                      onPressed: () => NavigatorMethods.pushNamedAndRemoveUntil(context, LoginScreen.routeName),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xffFD7201),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('ابدأ الآن', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                          SizedBox(width: 9),
                          Icon(Icons.arrow_forward_rounded),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingBackground extends StatelessWidget {
  const _OnboardingBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff24282E), Color(0xff171A1F), Color(0xff0F1114)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -90,
            top: 120,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xffFD7201).withOpacity(.08)),
            ),
          ),
          Positioned(
            left: -110,
            bottom: 70,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(.025)),
            ),
          ),
        ],
      ),
    );
  }
}
