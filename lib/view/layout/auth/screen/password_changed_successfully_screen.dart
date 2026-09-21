import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../custom_widgets/buttons/custom_button.dart';

class PasswordChangedSuccessfullyScreen extends StatelessWidget {
  static const String routeName = '/PasswordChangedSuccessfullyScreen';

  const PasswordChangedSuccessfullyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff171A1F);
    const softText = Color(0xff7D8490);
    const orange = Color(0xffFD7201);
    final isArabic = context.locale.languageCode == 'ar';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LayoutBuilder(
          builder: (context, viewport) {
            final compact = viewport.maxHeight < 780;
            final horizontalPadding = viewport.maxWidth < 420 ? 20.0 : 26.0;

            return Stack(
              children: [
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _SuccessBackgroundPainter()),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: compact ? 24 : 38,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: compact ? 28 : 55),
                            _SuccessIllustration(compact: compact),
                            SizedBox(height: compact ? 30 : 42),
                            Text(
                              AppLocaleKey.passwordChangedSuccessfully.tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: navy,
                                fontSize: compact ? 27 : 32,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 13),
                            Text(
                              isArabic
                                  ? 'تم تحديث كلمة المرور بنجاح، ويمكنك الآن استخدام كلمة المرور الجديدة بأمان.'
                                  : 'Your password has been updated successfully. You can now use your new password securely.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: softText,
                                fontSize: compact ? 15 : 16.5,
                                height: 1.55,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: compact ? 28 : 36),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 17,
                                vertical: 15,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.98),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xffF0F1F3)),
                                boxShadow: [
                                  BoxShadow(
                                    color: navy.withOpacity(.07),
                                    blurRadius: 23,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Row(
                                textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: const Color(0xffFFF3E8),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: const Icon(
                                      Icons.security_rounded,
                                      color: orange,
                                      size: 23,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      isArabic
                                          ? 'حسابك محمي بكلمة المرور الجديدة'
                                          : 'Your account is secured with the new password',
                                      style: const TextStyle(
                                        color: navy,
                                        fontSize: 14.5,
                                        height: 1.35,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: compact ? 58 : 95),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.only(bottom: 4),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: CustomButton(
              height: 60,
              radius: 20,
              hasShadow: true,
              text: AppLocaleKey.next.tr(),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xffFF8A08), Color(0xffFF6500)],
              ),
              suffixIcon: Icon(
                isArabic ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 24,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              boxShadow: [
                BoxShadow(
                  color: orange.withOpacity(.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessIllustration extends StatelessWidget {
  const _SuccessIllustration({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xffFD7201);
    const navy = Color(0xff171A1F);
    final size = compact ? 178.0 : 214.0;

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xffFFF7F0),
                border: Border.all(color: const Color(0xffFFE6D2)),
              ),
            ),
            Container(
              width: size * .67,
              height: size * .67,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xffFF9A17), Color(0xffFF6500)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: orange.withOpacity(.24),
                    blurRadius: 28,
                    offset: const Offset(0, 13),
                  ),
                ],
              ),
              child: Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: size * .36,
              ),
            ),
            Positioned(
              right: 3,
              top: size * .22,
              child: Container(
                width: size * .23,
                height: size * .23,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(size * .075),
                  boxShadow: [
                    BoxShadow(
                      color: navy.withOpacity(.10),
                      blurRadius: 16,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: orange,
                  size: size * .13,
                ),
              ),
            ),
            Positioned(
              left: 4,
              bottom: size * .16,
              child: Container(
                width: size * .20,
                height: size * .20,
                decoration: BoxDecoration(
                  color: const Color(0xffFFF0E4),
                  borderRadius: BorderRadius.circular(size * .065),
                ),
                child: Icon(
                  Icons.verified_user_outlined,
                  color: orange,
                  size: size * .12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessBackgroundPainter extends CustomPainter {
  const _SuccessBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const orange = Color(0xffFD7201);

    canvas.drawCircle(
      Offset(size.width * .06, 0),
      size.width * .36,
      Paint()..color = orange.withOpacity(.075),
    );
    canvas.drawCircle(
      Offset(size.width * .34, -28),
      size.width * .26,
      Paint()..color = orange.withOpacity(.03),
    );
    canvas.drawCircle(
      Offset(size.width * 1.03, size.height * .72),
      size.width * .32,
      Paint()..color = orange.withOpacity(.028),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
