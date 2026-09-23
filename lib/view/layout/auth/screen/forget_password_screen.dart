import 'package:flutter/material.dart';
import '../widget/partner_auth_scaffold.dart';
import 'partner_email_verification_screen.dart';
import 'partner_password_screen.dart';

class ForgetPasswordScreen extends StatefulWidget {
  static const String routeName = 'ForgetPasswordScreen';
  const ForgetPasswordScreen({super.key});
  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _mobile = TextEditingController();
  bool _busy = false;
  @override
  void dispose() {
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final mobile = _mobile.text.trim();
    final proof = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => PartnerEmailVerificationScreen(
          mobile: mobile,
          purpose: 'password_reset',
        ),
      ),
    );
    if (!mounted) return;
    if (proof != null) {
      final success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PartnerPasswordScreen(mobile: mobile, proof: proof),
        ),
      );
      if (!mounted) return;
      if (success == true) {
        Navigator.pop(context);
        return;
      }
    }
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => PartnerAuthScaffold(
    title: 'نسيت كلمة المرور؟',
    description:
        'اكتب رقم هاتف حسابك. هنرسل كود الاسترجاع على البريد الإلكتروني المسجل عندنا.',
    children: [
      Form(
        key: _form,
        child: TextFormField(
          controller: _mobile,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          autofillHints: const [AutofillHints.telephoneNumber],
          decoration: const InputDecoration(
            labelText: 'رقم الهاتف',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          validator: (v) => (v ?? '').replaceAll(RegExp(r'\D'), '').length < 10
              ? 'اكتب رقم هاتف صحيح'
              : null,
        ),
      ),
      const SizedBox(height: 24),
      PartnerAuthButton(
        label: 'إرسال الكود للبريد',
        onPressed: _continue,
        busy: _busy,
      ),
    ],
  );
}
