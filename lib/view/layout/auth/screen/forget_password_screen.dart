import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import 'verification_code_screen.dart';

class ForgetPasswordScreen extends StatefulWidget {
  static const String routeName = 'ForgetPasswordScreen';

  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final _mobileEc = TextEditingController();

  bool get _isArabic => context.locale.languageCode == 'ar';

  @override
  void dispose() {
    _mobileEc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff171A1F);
    const softText = Color(0xff7D8490);
    const orange = Color(0xffFD7201);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, viewport) {
          final compact = viewport.maxHeight < 820;
          final veryCompact = viewport.maxHeight < 700;
          final horizontalPadding = viewport.maxWidth < 420 ? 18.0 : 24.0;

          return Stack(
            children: [
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _ForgotPasswordBackgroundPainter()),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    8,
                    horizontalPadding,
                    MediaQuery.viewInsetsOf(context).bottom + 18,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: _isArabic ? Alignment.centerRight : Alignment.centerLeft,
                            child: _BackButton(onTap: () => Navigator.maybePop(context)),
                          ),
                          SizedBox(height: veryCompact ? 2 : 8),
                          _SecurityIllustration(
                            height: veryCompact ? 170 : (compact ? 205 : 235),
                          ),
                          SizedBox(height: veryCompact ? 8 : (compact ? 14 : 20)),
                          Text(
                            AppLocaleKey.didForgotPassword.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: navy,
                              fontSize: veryCompact ? 25 : (compact ? 28 : 31),
                              height: 1.18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: veryCompact ? 8 : 12),
                          Text(
                            AppLocaleKey
                                .donotWorryYouCanVerifyThePasswordThroughThePhoneRegisteredWithUs
                                .tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: softText,
                              fontSize: veryCompact ? 14 : (compact ? 15.5 : 17),
                              height: 1.55,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: veryCompact ? 18 : (compact ? 25 : 32)),
                          Container(
                            padding: EdgeInsets.fromLTRB(
                              compact ? 18 : 22,
                              compact ? 18 : 22,
                              compact ? 18 : 22,
                              compact ? 19 : 23,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.985),
                              borderRadius: BorderRadius.circular(compact ? 25 : 29),
                              border: Border.all(color: const Color(0xffF0F1F3)),
                              boxShadow: [
                                BoxShadow(
                                  color: navy.withOpacity(.08),
                                  blurRadius: compact ? 24 : 32,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  AppLocaleKey.mobileNumber.tr(),
                                  textAlign: _isArabic ? TextAlign.right : TextAlign.left,
                                  style: TextStyle(
                                    color: navy,
                                    fontSize: compact ? 16 : 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: compact ? 10 : 12),
                                CustomFormField(
                                  controller: _mobileEc,
                                  keyboardType: TextInputType.phone,
                                  textDirection: ui.TextDirection.ltr,
                                  hintText: '01XXXXXXXXX',
                                  radius: 18,
                                  hasShadow: false,
                                  fillColor: Colors.white,
                                  unFocusColor: const Color(0xffDADDE2),
                                  textStyle: TextStyle(
                                    color: navy,
                                    fontSize: compact ? 16 : 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  hintStyle: TextStyle(
                                    color: const Color(0xffB2B6BD),
                                    fontSize: compact ? 15.5 : 16.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: compact ? 16 : 18,
                                    horizontal: 14,
                                  ),
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  prefixIcon: Container(
                                    width: 48,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.phone_in_talk_outlined,
                                      size: 23,
                                      color: Color(0xffAEB3BA),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: veryCompact ? 20 : (compact ? 28 : 36)),
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
              _isArabic ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
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
            onPressed: () {
              NavigatorMethods.pushNamed(context, VerificationCodeScreen.routeName);
            },
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xffF0F1F3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff171A1F).withOpacity(.08),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xffFD7201),
            size: 27,
          ),
        ),
      ),
    );
  }
}

class _SecurityIllustration extends StatelessWidget {
  const _SecurityIllustration({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xffFD7201);
    const navy = Color(0xff171A1F);

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, box) {
          final scale = (box.maxHeight / 235).clamp(.72, 1.0).toDouble();
          final phoneWidth = 104.0 * scale;
          final phoneHeight = 178.0 * scale;

          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: box.maxWidth * .07,
                top: 28 * scale,
                child: _SoftIconBubble(
                  size: 58 * scale,
                  icon: Icons.more_horiz_rounded,
                ),
              ),
              Positioned(
                left: box.maxWidth * .13,
                bottom: 26 * scale,
                child: Icon(
                  Icons.location_on_outlined,
                  size: 38 * scale,
                  color: orange.withOpacity(.30),
                ),
              ),
              Container(
                width: phoneWidth,
                height: phoneHeight,
                padding: EdgeInsets.symmetric(
                  horizontal: 10 * scale,
                  vertical: 16 * scale,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25 * scale),
                  border: Border.all(color: orange, width: 3 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: orange.withOpacity(.16),
                      blurRadius: 24 * scale,
                      offset: Offset(0, 11 * scale),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52 * scale,
                      height: 52 * scale,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xffFF920B), Color(0xffFF6500)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15 * scale),
                        boxShadow: [
                          BoxShadow(
                            color: orange.withOpacity(.20),
                            blurRadius: 12 * scale,
                            offset: Offset(0, 6 * scale),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        color: Colors.white,
                        size: 29 * scale,
                      ),
                    ),
                    SizedBox(height: 17 * scale),
                    Container(
                      height: 28 * scale,
                      padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                      decoration: BoxDecoration(
                        color: const Color(0xffFFF5EC),
                        borderRadius: BorderRadius.circular(10 * scale),
                        border: Border.all(color: const Color(0xffFFD8B8)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          4,
                          (_) => Container(
                            width: 5 * scale,
                            height: 5 * scale,
                            decoration: const BoxDecoration(
                              color: orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: box.maxWidth * .17,
                bottom: 22 * scale,
                child: Container(
                  width: 65 * scale,
                  height: 65 * scale,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(21 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: navy.withOpacity(.10),
                        blurRadius: 18 * scale,
                        offset: Offset(0, 8 * scale),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.verified_user_rounded,
                    color: orange,
                    size: 44 * scale,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SoftIconBubble extends StatelessWidget {
  const _SoftIconBubble({required this.size, required this.icon});

  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * .34),
        border: Border.all(color: const Color(0xffF3EAE3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffFD7201).withOpacity(.08),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: size * .48,
        color: const Color(0xffFD7201),
      ),
    );
  }
}

class _ForgotPasswordBackgroundPainter extends CustomPainter {
  const _ForgotPasswordBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const orange = Color(0xffFD7201);

    final topGlow = Paint()..color = orange.withOpacity(.08);
    final topGlow2 = Paint()..color = orange.withOpacity(.035);
    final line = Paint()
      ..color = orange.withOpacity(.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawCircle(Offset(size.width * .04, 8), size.width * .34, topGlow);
    canvas.drawCircle(Offset(size.width * .31, -18), size.width * .27, topGlow2);

    final path = Path()
      ..moveTo(-15, size.height * .20)
      ..cubicTo(
        size.width * .12,
        size.height * .11,
        size.width * .24,
        size.height * .09,
        size.width * .36,
        size.height * .08,
      );
    canvas.drawPath(path, line);

    final bottomGlow = Paint()..color = orange.withOpacity(.025);
    canvas.drawCircle(
      Offset(size.width * 1.03, size.height * .72),
      size.width * .34,
      bottomGlow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
