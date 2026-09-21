import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/validation/validation_mixin.dart';
import 'password_changed_successfully_screen.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  static const String routeName = 'CreateNewPasswordScreen';

  const CreateNewPasswordScreen({super.key});

  @override
  State<CreateNewPasswordScreen> createState() => _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen>
    with ValidationMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordEc = TextEditingController();
  final _confirmPasswordEc = TextEditingController();

  bool get _isArabic => context.locale.languageCode == 'ar';

  @override
  void dispose() {
    _passwordEc.dispose();
    _confirmPasswordEc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff171A1F);
    const softText = Color(0xff7D8490);
    const orange = Color(0xffFD7201);

    return Form(
      key: _formKey,
      child: Scaffold(
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
                    child: CustomPaint(painter: _PasswordBackgroundPainter()),
                  ),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      8,
                      horizontalPadding,
                      MediaQuery.viewInsetsOf(context).bottom + 22,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment:
                                  _isArabic ? Alignment.centerRight : Alignment.centerLeft,
                              child: _PremiumBackButton(
                                onTap: () => Navigator.maybePop(context),
                              ),
                            ),
                            SizedBox(height: veryCompact ? 3 : 10),
                            _PasswordIllustration(
                              height: veryCompact ? 155 : (compact ? 188 : 220),
                            ),
                            SizedBox(height: veryCompact ? 8 : 16),
                            Text(
                              AppLocaleKey.createNewPassword.tr(),
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
                              AppLocaleKey.createNewPasswordToKeepYourDataSafe.tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: softText,
                                fontSize: veryCompact ? 14 : (compact ? 15.5 : 17),
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: veryCompact ? 18 : (compact ? 24 : 31)),
                            Container(
                              padding: EdgeInsets.fromLTRB(
                                compact ? 18 : 22,
                                compact ? 19 : 23,
                                compact ? 18 : 22,
                                compact ? 20 : 24,
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
                                  _FieldLabel(
                                    text: AppLocaleKey.password.tr(),
                                    isArabic: _isArabic,
                                    compact: compact,
                                  ),
                                  SizedBox(height: compact ? 9 : 11),
                                  CustomFormField(
                                    controller: _passwordEc,
                                    validator: validateNewPassword,
                                    isPassword: true,
                                    textDirection: ui.TextDirection.ltr,
                                    radius: 18,
                                    hasShadow: false,
                                    fillColor: Colors.white,
                                    unFocusColor: const Color(0xffDADDE2),
                                    passwordColor: const Color(0xffAEB3BA),
                                    textStyle: TextStyle(
                                      color: navy,
                                      fontSize: compact ? 16 : 17,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 3,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: compact ? 15 : 18,
                                      horizontal: 13,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 23,
                                      color: Color(0xffAEB3BA),
                                    ),
                                  ),
                                  SizedBox(height: compact ? 17 : 22),
                                  _FieldLabel(
                                    text: AppLocaleKey.confirmPassword.tr(),
                                    isArabic: _isArabic,
                                    compact: compact,
                                  ),
                                  SizedBox(height: compact ? 9 : 11),
                                  CustomFormField(
                                    controller: _confirmPasswordEc,
                                    validator: validateConfirmPassword,
                                    isPassword: true,
                                    textDirection: ui.TextDirection.ltr,
                                    radius: 18,
                                    hasShadow: false,
                                    fillColor: Colors.white,
                                    unFocusColor: const Color(0xffDADDE2),
                                    passwordColor: const Color(0xffAEB3BA),
                                    textStyle: TextStyle(
                                      color: navy,
                                      fontSize: compact ? 16 : 17,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 3,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: compact ? 15 : 18,
                                      horizontal: 13,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.verified_user_outlined,
                                      size: 23,
                                      color: Color(0xffAEB3BA),
                                    ),
                                  ),
                                  SizedBox(height: compact ? 12 : 15),
                                  Row(
                                    textDirection: _isArabic
                                        ? ui.TextDirection.rtl
                                        : ui.TextDirection.ltr,
                                    children: [
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: const Color(0xffFFF3E8),
                                          borderRadius: BorderRadius.circular(9),
                                        ),
                                        child: const Icon(
                                          Icons.security_rounded,
                                          size: 18,
                                          color: orange,
                                        ),
                                      ),
                                      const SizedBox(width: 9),
                                      Expanded(
                                        child: Text(
                                          _isArabic
                                              ? 'استخدم كلمة مرور قوية لا تقل عن 6 أحرف'
                                              : 'Use a strong password with at least 6 characters',
                                          style: TextStyle(
                                            color: softText,
                                            fontSize: compact ? 12.5 : 13.5,
                                            height: 1.35,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
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
                if (_formKey.currentState?.validate() ?? false) {
                  NavigatorMethods.pushNamed(
                    context,
                    PasswordChangedSuccessfullyScreen.routeName,
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.text,
    required this.isArabic,
    required this.compact,
  });

  final String text;
  final bool isArabic;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: isArabic ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        color: const Color(0xff171A1F),
        fontSize: compact ? 16 : 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PremiumBackButton extends StatelessWidget {
  const _PremiumBackButton({required this.onTap});

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

class _PasswordIllustration extends StatelessWidget {
  const _PasswordIllustration({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xffFD7201);
    const navy = Color(0xff171A1F);

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, box) {
          final scale = (box.maxHeight / 220).clamp(.70, 1.0).toDouble();

          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 142 * scale,
                height: 142 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xffFFF6EE),
                  border: Border.all(color: const Color(0xffFFE5CF)),
                ),
              ),
              Container(
                width: 92 * scale,
                height: 116 * scale,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28 * scale),
                  border: Border.all(color: orange, width: 3 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: orange.withOpacity(.15),
                      blurRadius: 24 * scale,
                      offset: Offset(0, 11 * scale),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.lock_reset_rounded,
                  color: orange,
                  size: 53 * scale,
                ),
              ),
              Positioned(
                right: box.maxWidth * .19,
                top: 34 * scale,
                child: Container(
                  width: 53 * scale,
                  height: 53 * scale,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: navy.withOpacity(.09),
                        blurRadius: 16 * scale,
                        offset: Offset(0, 7 * scale),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    color: orange,
                    size: 31 * scale,
                  ),
                ),
              ),
              Positioned(
                left: box.maxWidth * .17,
                bottom: 30 * scale,
                child: Container(
                  width: 49 * scale,
                  height: 49 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0xffFFF3E8),
                    borderRadius: BorderRadius.circular(16 * scale),
                  ),
                  child: Icon(
                    Icons.password_rounded,
                    color: orange,
                    size: 29 * scale,
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

class _PasswordBackgroundPainter extends CustomPainter {
  const _PasswordBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const orange = Color(0xffFD7201);

    canvas.drawCircle(
      Offset(size.width * .04, 8),
      size.width * .34,
      Paint()..color = orange.withOpacity(.08),
    );
    canvas.drawCircle(
      Offset(size.width * .31, -18),
      size.width * .27,
      Paint()..color = orange.withOpacity(.035),
    );

    final accent = Paint()
      ..color = orange.withOpacity(.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..moveTo(-18, size.height * .19)
      ..cubicTo(
        size.width * .11,
        size.height * .11,
        size.width * .24,
        size.height * .085,
        size.width * .37,
        size.height * .075,
      );
    canvas.drawPath(path, accent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
