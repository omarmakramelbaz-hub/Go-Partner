import 'dart:ui' as ui;

import 'package:custom_timer/custom_timer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

import '../../../../../helpers/extension/context_extension.dart';
import '../../../../../helpers/locale/app_locale_key.dart';
import '../../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_toast/custom_toast.dart';
import 'create_new_password_screen.dart';

class VerificationCodeScreen extends StatefulWidget {
  static const routeName = 'VerificationCodeScreen';

  const VerificationCodeScreen({super.key});

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _codeEC = TextEditingController();

  late final CustomTimerController _timerController = CustomTimerController(
    vsync: this,
    begin: const Duration(minutes: 2),
    end: const Duration(),
    initialState: CustomTimerState.reset,
    interval: CustomTimerInterval.milliseconds,
  );

  bool get _isArabic => context.locale.languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _timerController.reset();
    _timerController.start();
  }

  @override
  void dispose() {
    _timerController.dispose();
    _codeEC.dispose();
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
                    child: CustomPaint(painter: _VerificationBackgroundPainter()),
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
                            _CodeIllustration(
                              height: veryCompact ? 165 : (compact ? 200 : 228),
                            ),
                            SizedBox(height: veryCompact ? 8 : (compact ? 14 : 20)),
                            Text(
                              tr(AppLocaleKey.verificationCode),
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
                              tr(AppLocaleKey.pleaseEnterTheVerificationCodeSentToTheNumber),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: softText,
                                fontSize: veryCompact ? 14 : (compact ? 15.5 : 17),
                                height: 1.55,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: veryCompact ? 18 : (compact ? 24 : 30)),
                            Container(
                              padding: EdgeInsets.fromLTRB(
                                compact ? 15 : 20,
                                compact ? 20 : 24,
                                compact ? 15 : 20,
                                compact ? 18 : 22,
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
                                children: [
                                  LayoutBuilder(
                                    builder: (context, box) {
                                      final pinWidth = ((box.maxWidth - 36) / 4).clamp(54.0, 72.0).toDouble();
                                      final pinHeight = compact ? 62.0 : 68.0;

                                      final defaultPinTheme = PinTheme(
                                        width: pinWidth,
                                        height: pinHeight,
                                        textStyle: TextStyle(
                                          color: navy,
                                          fontSize: compact ? 21 : 23,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xffFBFBFC),
                                          borderRadius: BorderRadius.circular(17),
                                          border: Border.all(color: const Color(0xffDADDE2)),
                                        ),
                                      );

                                      return Directionality(
                                        textDirection: ui.TextDirection.ltr,
                                        child: Pinput(
                                          length: 4,
                                          controller: _codeEC,
                                          keyboardType: TextInputType.number,
                                          defaultPinTheme: defaultPinTheme,
                                          focusedPinTheme: defaultPinTheme.copyWith(
                                            decoration: defaultPinTheme.decoration?.copyWith(
                                              color: const Color(0xffFFF8F1),
                                              border: Border.all(color: orange, width: 1.7),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: orange.withOpacity(.10),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                          ),
                                          submittedPinTheme: defaultPinTheme.copyWith(
                                            decoration: defaultPinTheme.decoration?.copyWith(
                                              color: const Color(0xffFFF9F3),
                                              border: Border.all(color: const Color(0xffFFB36E)),
                                            ),
                                          ),
                                          errorPinTheme: defaultPinTheme.copyWith(
                                            decoration: defaultPinTheme.decoration?.copyWith(
                                              border: Border.all(color: const Color(0xffD94141)),
                                            ),
                                          ),
                                          separatorBuilder: (_) => const SizedBox(width: 12),
                                          validator: (value) {
                                            if ((value ?? '').trim().length == 4) return null;
                                            return context.apiTr(
                                              ar: 'الكود مكون من 4 أرقام',
                                              en: 'The code consists of 4 digits',
                                            );
                                          },
                                          pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                                          errorTextStyle: const TextStyle(
                                            color: Color(0xffD94141),
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(height: compact ? 19 : 24),
                                  CustomTimer(
                                    controller: _timerController,
                                    builder: (state, time) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xffFFF5EC),
                                          borderRadius: BorderRadius.circular(15),
                                          border: Border.all(color: const Color(0xffFFE0C5)),
                                        ),
                                        child: Directionality(
                                          textDirection: ui.TextDirection.ltr,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.schedule_rounded,
                                                size: 20,
                                                color: orange,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${time.minutes}:${time.seconds}',
                                                style: TextStyle(
                                                  color: navy,
                                                  fontSize: compact ? 16 : 17,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: .5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(height: compact ? 10 : 13),
                                  TextButton.icon(
                                    onPressed: _resendCode,
                                    style: TextButton.styleFrom(
                                      foregroundColor: orange,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: const Icon(Icons.refresh_rounded, size: 21),
                                    label: Text(
                                      context.apiTr(ar: 'إرسال مرة أخرى', en: 'Resend Code'),
                                      style: TextStyle(
                                        color: orange,
                                        fontSize: compact ? 14.5 : 15.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: veryCompact ? 18 : (compact ? 26 : 34)),
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
              text: tr(AppLocaleKey.next),
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
              onPressed: _continue,
            ),
          ),
        ),
      ),
    );
  }

  void _resendCode() {
    if (_timerController.state.value == CustomTimerState.finished) {
      _codeEC.clear();
      _timerController.reset();
      _timerController.start();
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }

    CommonMethods.showToast(
      message: context.apiTr(ar: 'انتظر لنهاية الوقت', en: 'Wait for the timer to finish'),
      type: ToastType.warning,
      backgroundColor: const Color(0xffFD7201),
    );
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    NavigatorMethods.pushNamed(context, CreateNewPasswordScreen.routeName);
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

class _CodeIllustration extends StatelessWidget {
  const _CodeIllustration({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xffFD7201);
    const navy = Color(0xff171A1F);

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, box) {
          final scale = (box.maxHeight / 228).clamp(.72, 1.0).toDouble();

          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: box.maxWidth * .09,
                top: 30 * scale,
                child: _SoftBubble(
                  size: 54 * scale,
                  child: Icon(
                    Icons.sms_outlined,
                    size: 27 * scale,
                    color: orange,
                  ),
                ),
              ),
              Positioned(
                right: box.maxWidth * .10,
                bottom: 30 * scale,
                child: _SoftBubble(
                  size: 56 * scale,
                  child: Icon(
                    Icons.verified_user_rounded,
                    size: 31 * scale,
                    color: orange,
                  ),
                ),
              ),
              Container(
                width: 154 * scale,
                padding: EdgeInsets.fromLTRB(
                  18 * scale,
                  18 * scale,
                  18 * scale,
                  20 * scale,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28 * scale),
                  border: Border.all(color: const Color(0xffFFE0C6)),
                  boxShadow: [
                    BoxShadow(
                      color: orange.withOpacity(.15),
                      blurRadius: 28 * scale,
                      offset: Offset(0, 12 * scale),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58 * scale,
                      height: 58 * scale,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xffFF920B), Color(0xffFF6500)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18 * scale),
                        boxShadow: [
                          BoxShadow(
                            color: orange.withOpacity(.22),
                            blurRadius: 13 * scale,
                            offset: Offset(0, 6 * scale),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.mark_email_read_outlined,
                        color: Colors.white,
                        size: 31 * scale,
                      ),
                    ),
                    SizedBox(height: 19 * scale),
                    Directionality(
                      textDirection: ui.TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          4,
                          (index) => Container(
                            width: 22 * scale,
                            height: 25 * scale,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xffFFF5EC),
                              borderRadius: BorderRadius.circular(7 * scale),
                              border: Border.all(color: const Color(0xffFFD6B3)),
                            ),
                            child: Container(
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
                    ),
                  ],
                ),
              ),
              Positioned(
                right: box.maxWidth * .23,
                top: 30 * scale,
                child: Container(
                  width: 42 * scale,
                  height: 42 * scale,
                  decoration: BoxDecoration(
                    color: navy,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: navy.withOpacity(.16),
                        blurRadius: 12 * scale,
                        offset: Offset(0, 5 * scale),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 25 * scale,
                    color: Colors.white,
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

class _SoftBubble extends StatelessWidget {
  const _SoftBubble({required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
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
      child: child,
    );
  }
}

class _VerificationBackgroundPainter extends CustomPainter {
  const _VerificationBackgroundPainter();

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
