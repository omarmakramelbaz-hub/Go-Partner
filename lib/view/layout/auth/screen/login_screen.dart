import 'dart:ui' as ui;

import 'package:country_picker/country_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extension/string_extension.dart';
import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/utils/country_code_methods.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/validation/validation_mixin.dart';
import '../../delegate_bottom_nav_bar.dart/screen/delegate_bottom_nav_bar_screen.dart';
import '../controller/auth_controller.dart';
import 'forget_password_screen.dart';
import 'partner_application_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String routeName = 'LoginScreen';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with ValidationMixin {
  final _mobileEc = TextEditingController();
  final _passwordEc = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Country? _country;

  bool get _isArabic => context.locale.languageCode == 'ar';

  @override
  void initState() {
    _country = CountryCodeMethods.getByCode('20');
    super.initState();
  }

  @override
  void dispose() {
    _mobileEc.dispose();
    _passwordEc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff082A4D);
    const softText = Color(0xff7D8490);
    const orange = Color(0xffFD7201);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, viewport) {
          final compact = viewport.maxHeight < 860;
          final veryCompact = viewport.maxHeight < 720;
          final logoSize = veryCompact ? 116.0 : (compact ? 148.0 : 184.0);
          final horizontalPadding = viewport.maxWidth < 420 ? 18.0 : 24.0;

          return Stack(
            children: [
              const Positioned.fill(
                child: IgnorePointer(child: CustomPaint(painter: _LoginBackgroundPainter())),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    veryCompact ? 4 : 8,
                    horizontalPadding,
                    MediaQuery.viewInsetsOf(context).bottom + (veryCompact ? 16 : 24),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 520,
                        minHeight: viewport.maxHeight - MediaQuery.paddingOf(context).vertical - 34,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(height: veryCompact ? 4 : (compact ? 10 : 14)),
                            SizedBox(
                              child: SvgPicture.asset(
                                'assets/svg/go_partner_logo.svg',
                                width: logoSize * 1.9,
                                height: logoSize,
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(height: veryCompact ? 4 : (compact ? 7 : 10)),
                            Text(
                              _isArabic
                                  ? 'أهلاً بك في GO Partner — أدخل بيانات حساب الشريك'
                                  : 'Welcome to GO Partner — enter your partner account details',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: softText,
                                fontSize: veryCompact ? 13.5 : (compact ? 15 : 16.5),
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: veryCompact ? 12 : (compact ? 16 : 22)),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.fromLTRB(
                                compact ? 19 : 24,
                                compact ? 20 : 26,
                                compact ? 19 : 24,
                                compact ? 18 : 23,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.985),
                                borderRadius: BorderRadius.circular(compact ? 27 : 31),
                                border: Border.all(color: const Color(0xffF1F2F4)),
                                boxShadow: [
                                  BoxShadow(
                                    color: navy.withOpacity(.09),
                                    blurRadius: compact ? 25 : 34,
                                    offset: const Offset(0, 13),
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
                                  SizedBox(height: compact ? 9 : 12),
                                  CustomFormField(
                                    controller: _mobileEc,
                                    validator: (v) => validatePhone(v, country: _country),
                                    keyboardType: TextInputType.phone,
                                    textDirection: ui.TextDirection.ltr,
                                    hintText: '10XXX:XXXX',
                                    radius: 17,
                                    hasShadow: false,
                                    fillColor: Colors.white,
                                    unFocusColor: const Color(0xffDADDE2),
                                    textStyle: TextStyle(
                                      color: navy,
                                      fontSize: compact ? 16 : 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    hintStyle: TextStyle(
                                      color: const Color(0xffADB1B8),
                                      fontSize: compact ? 16 : 17,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: compact ? 15 : 18,
                                      horizontal: 13,
                                    ),
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    prefixIcon: Padding(
                                      padding: const EdgeInsetsDirectional.only(start: 13, end: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${_country?.flagEmoji ?? '🇪🇬'}  +${_country?.phoneCode ?? '20'}',
                                            textDirection: ui.TextDirection.ltr,
                                            style: TextStyle(
                                              color: navy,
                                              fontSize: compact ? 16 : 17,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 19,
                                            color: Color(0xffAEB3BA),
                                          ),
                                          const SizedBox(width: 7),
                                          Container(width: 1, height: 26, color: const Color(0xffE1E3E7)),
                                        ],
                                      ),
                                    ),
                                    suffixIcon: const Icon(
                                      Icons.phone_in_talk_outlined,
                                      size: 23,
                                      color: Color(0xffAEB3BA),
                                    ),
                                  ),
                                  SizedBox(height: compact ? 17 : 23),
                                  Text(
                                    AppLocaleKey.password.tr(),
                                    textAlign: _isArabic ? TextAlign.right : TextAlign.left,
                                    style: TextStyle(
                                      color: navy,
                                      fontSize: compact ? 16 : 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: compact ? 9 : 12),
                                  CustomFormField(
                                    controller: _passwordEc,
                                    isPassword: true,
                                    textDirection: ui.TextDirection.ltr,
                                    radius: 17,
                                    hasShadow: false,
                                    fillColor: Colors.white,
                                    unFocusColor: const Color(0xffDADDE2),
                                    passwordColor: const Color(0xffAEB3BA),
                                    textStyle: TextStyle(
                                      color: navy,
                                      fontSize: compact ? 16 : 17,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 4,
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
                                  Align(
                                    alignment: _isArabic ? Alignment.centerLeft : Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        NavigatorMethods.pushNamed(context, ForgetPasswordScreen.routeName);
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: orange,
                                        padding: EdgeInsets.only(top: compact ? 8 : 10, bottom: compact ? 4 : 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        _isArabic ? 'نسيت كلمة المرور؟' : 'Forgot password?',
                                        style: TextStyle(
                                          color: orange,
                                          fontSize: compact ? 14 : 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: compact ? 13 : 18),
                                  CustomButton(
                                    height: compact ? 56 : 61,
                                    radius: 19,
                                    hasShadow: true,
                                    text: AppLocaleKey.login.tr(),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Color(0xffFF8A08), Color(0xffFF6500)],
                                    ),
                                    suffixIcon: const Icon(
                                      Icons.login_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: compact ? 19 : 21,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: orange.withOpacity(.28),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                    onPressed: _login,
                                  ),
                                  SizedBox(height: compact ? 17 : 23),
                                  Directionality(
                                    textDirection: _isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 1,
                                      children: [
                                        Text(
                                          _isArabic ? 'تريد الانضمام كشريك؟' : 'Want to join as a partner?',
                                          style: TextStyle(
                                            color: const Color(0xff646B75),
                                            fontSize: compact ? 14.5 : 15.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _openRegistration,
                                          style: TextButton.styleFrom(
                                            foregroundColor: orange,
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: Text(
                                            _isArabic ? 'قدّم طلب انضمام' : 'Apply now',
                                            style: TextStyle(
                                              color: orange,
                                              fontSize: compact ? 15 : 16,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TextButton.icon(
                                    onPressed: _trackApplication,
                                    icon: const Icon(
                                      Icons.manage_search_rounded,
                                      size: 19,
                                    ),
                                    label: Text(
                                      _isArabic
                                          ? 'متابعة طلب الانضمام'
                                          : 'Track application',
                                      style: TextStyle(
                                        fontSize: compact ? 13.5 : 14.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: navy,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: veryCompact ? 34 : (compact ? 50 : 72)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthController>().login(
      onHaveId: (id, token) {
        context.read<PusherController>().initPusher(
          channelName: 'private-user.$id',
          userId: id,
          token: token,
        );
      },
      mobile: _mobileEc.text.removeZero(),
      password: _passwordEc.text,
      onSuccess: (accountType) {
        if (accountType == 'delegate') {
          NavigatorMethods.pushNamedAndRemoveUntil(context, DelegateBottomNavBarScreen.routeName);
        }
      },
    );
  }

  void _openRegistration() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PartnerApplicationScreen(),
      ),
    );
  }

  void _trackApplication() {
    final mobile = _mobileEc.text.trim();
    if (mobile.replaceAll(RegExp(r'\D'), '').length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isArabic
                ? 'اكتب رقم الهاتف المستخدم في طلب الانضمام أولاً.'
                : 'Enter the phone number used in your application first.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PartnerApplicationSubmittedScreen(mobile: mobile),
      ),
    );
  }
}

class _LoginBackgroundPainter extends CustomPainter {
  const _LoginBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const orange = Color(0xffFD7201);

    final topGlow = Paint()..color = orange.withOpacity(.11);
    final topAccent = Paint()..color = orange;
    final bottomGlow = Paint()..color = orange.withOpacity(.14);
    final bottomAccent = Paint()..color = orange;

    final glowPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * .50, 0)
      ..quadraticBezierTo(size.width * .23, 38, 0, 157)
      ..close();
    canvas.drawPath(glowPath, topGlow);

    final topPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * .37, 0)
      ..quadraticBezierTo(size.width * .16, 31, 0, 112)
      ..close();
    canvas.drawPath(topPath, topAccent);

    final lowerGlowPath = Path()
      ..moveTo(size.width, size.height * .73)
      ..quadraticBezierTo(size.width * .93, size.height * .84, size.width * .72, size.height * .91)
      ..quadraticBezierTo(size.width * .49, size.height * .98, size.width * .27, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(lowerGlowPath, bottomGlow);

    final lowerAccentPath = Path()
      ..moveTo(size.width, size.height * .82)
      ..quadraticBezierTo(size.width * .87, size.height * .93, size.width * .60, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(lowerAccentPath, bottomAccent);

    final wavePaint = Paint()
      ..color = orange.withOpacity(.075)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;
    for (var index = 0; index < 7; index++) {
      final y = size.height * .285 + (index * 12);
      final wavePath = Path()
        ..moveTo(0, y)
        ..cubicTo(size.width * .18, y - 9, size.width * .32, y + 8, size.width * .50, y)
        ..cubicTo(size.width * .67, y - 8, size.width * .84, y + 9, size.width, y - 1);
      canvas.drawPath(wavePath, wavePaint);
    }

    final sceneWidth = size.width > 520 ? 520.0 : size.width;
    _drawBoat(
      canvas,
      Offset(size.width * .14, size.height * .30),
      sceneWidth * .15,
      orange.withOpacity(.14),
    );
    _drawBoat(
      canvas,
      Offset(size.width * .86, size.height * .275),
      sceneWidth * .12,
      orange.withOpacity(.12),
      facingLeft: true,
    );

    _drawBird(canvas, Offset(size.width * .19, size.height * .16), 9, orange.withOpacity(.30));
    _drawBird(canvas, Offset(size.width * .82, size.height * .13), 10, orange.withOpacity(.30));
    _drawBird(canvas, Offset(size.width * .88, size.height * .20), 7, orange.withOpacity(.24));
  }

  void _drawBird(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(center.dx - radius, center.dy)
      ..quadraticBezierTo(center.dx - radius * .45, center.dy - radius * .60, center.dx, center.dy)
      ..quadraticBezierTo(center.dx + radius * .45, center.dy - radius * .60, center.dx + radius, center.dy);
    canvas.drawPath(path, paint);
  }

  void _drawBoat(
    Canvas canvas,
    Offset center,
    double width,
    Color color, {
    bool facingLeft = false,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (facingLeft) canvas.scale(-1, 1);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color.withOpacity(.34)
      ..style = PaintingStyle.fill;

    final hull = Path()
      ..moveTo(-width * .55, 0)
      ..lineTo(width * .56, 0)
      ..quadraticBezierTo(width * .35, width * .24, -width * .30, width * .22)
      ..close();
    canvas.drawPath(hull, fill);
    canvas.drawPath(hull, stroke);

    canvas.drawLine(Offset(-width * .03, 0), Offset(-width * .03, -width * .57), stroke);
    final cabin = Path()
      ..moveTo(-width * .32, 0)
      ..lineTo(-width * .22, -width * .18)
      ..lineTo(width * .17, -width * .18)
      ..lineTo(width * .28, 0);
    canvas.drawPath(cabin, stroke);
    canvas.drawLine(
      Offset(-width * .03, -width * .50),
      Offset(width * .28, -width * .31),
      stroke,
    );
    canvas.drawLine(
      Offset(width * .28, -width * .31),
      Offset(-width * .03, -width * .31),
      stroke,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
