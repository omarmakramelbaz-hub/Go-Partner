import 'dart:ui' as ui;

import 'package:country_picker/country_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extension/string_extension.dart';
import '../../../../helpers/identity/partner_app_identity.dart';
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
import 'partner_type_screen.dart';

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
    const charcoal = Color(0xff171A1F);
    const muted = Color(0xff737B86);
    const orange = Color(0xffFD7201);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final compact = viewport.maxHeight < 700;
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(24, compact ? 20 : 42, 24, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: SvgPicture.asset(
                            PartnerAppIdentity.logoAsset,
                            width: compact ? 154 : 184,
                            height: compact ? 118 : 141,
                            semanticsLabel: PartnerAppIdentity.displayName,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 23, height: 3, color: orange),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _isArabic
                                    ? 'معًا نصنع الفرص'
                                    : 'Creating opportunities together',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: charcoal,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(width: 23, height: 3, color: orange),
                          ],
                        ),
                        SizedBox(height: compact ? 26 : 36),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xffF4F5F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Semantics(
                                  selected: true,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: orange,
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Text(
                                      _isArabic ? 'تسجيل الدخول' : 'Sign in',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextButton(
                                  onPressed: _openRegistration,
                                  style: TextButton.styleFrom(
                                    foregroundColor: charcoal,
                                  ),
                                  child: Text(
                                    _isArabic ? 'إنشاء حساب' : 'Create account',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        CustomFormField(
                          controller: _mobileEc,
                          validator: (v) => validatePhone(v, country: _country),
                          title: _isArabic ? 'رقم الهاتف' : 'Phone number',
                          keyboardType: TextInputType.phone,
                          textDirection: ui.TextDirection.ltr,
                          hintText: '10X XXX XXXX',
                          radius: 12,
                          hasShadow: false,
                          fillColor: Colors.white,
                          unFocusColor: const Color(0xffE3E6EA),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 14,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          prefixIcon: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '+20',
                                  style: TextStyle(
                                    color: charcoal,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 10),
                                SizedBox(
                                  height: 22,
                                  child: VerticalDivider(
                                    width: 1,
                                    color: Color(0xffE3E6EA),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          suffixIcon: const Icon(
                            Icons.phone_outlined,
                            color: muted,
                            size: 21,
                          ),
                        ),
                        const SizedBox(height: 18),
                        CustomFormField(
                          controller: _passwordEc,
                          title: _isArabic ? 'كلمة المرور' : 'Password',
                          isPassword: true,
                          textDirection: ui.TextDirection.ltr,
                          radius: 12,
                          hasShadow: false,
                          fillColor: Colors.white,
                          unFocusColor: const Color(0xffE3E6EA),
                          passwordColor: muted,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: muted,
                            size: 21,
                          ),
                          onFieldSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 26),
                        CustomButton(
                          height: 54,
                          radius: 12,
                          hasShadow: false,
                          color: orange,
                          text: _isArabic ? 'تسجيل الدخول' : 'Sign in',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                          onPressed: _login,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => NavigatorMethods.pushNamed(
                            context,
                            ForgetPasswordScreen.routeName,
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: charcoal,
                          ),
                          child: Text(
                            _isArabic
                                ? 'نسيت كلمة المرور؟'
                                : 'Forgot password?',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Divider(color: Color(0xffEEF0F3)),
                        const SizedBox(height: 12),
                        Text(
                          _isArabic
                              ? 'خطوتك الأولى لفرص أكبر'
                              : 'Your first step to more opportunities',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: muted, height: 1.5),
                        ),
                        TextButton(
                          onPressed: _openRegistration,
                          style: TextButton.styleFrom(foregroundColor: orange),
                          child: Text(
                            _isArabic
                                ? 'قدّم طلب انضمام كشريك'
                                : 'Apply to become a partner',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _trackApplication,
                          icon: const Icon(
                            Icons.manage_search_rounded,
                            size: 21,
                          ),
                          label: Text(
                            _isArabic
                                ? 'متابعة طلب الانضمام'
                                : 'Track application',
                          ),
                          style: TextButton.styleFrom(foregroundColor: muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
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
          NavigatorMethods.pushNamedAndRemoveUntil(
            context,
            DelegateBottomNavBarScreen.routeName,
          );
        }
      },
    );
  }

  void _openRegistration() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PartnerTypeScreen()));
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
