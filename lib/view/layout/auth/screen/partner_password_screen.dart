import 'package:flutter/material.dart';
import '../../../../helpers/networking/partner_email_auth.dart';
import '../widget/partner_auth_scaffold.dart';

class PartnerPasswordScreen extends StatefulWidget {
  const PartnerPasswordScreen({
    super.key,
    required this.mobile,
    required this.proof,
    this.activation = false,
  });
  final String mobile;
  final String proof;
  final bool activation;
  @override
  State<PartnerPasswordScreen> createState() => _PartnerPasswordScreenState();
}

class _PartnerPasswordScreenState extends State<PartnerPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await PartnerEmailAuth().setPassword(
        activation: widget.activation,
        mobile: widget.mobile,
        proof: widget.proof,
        password: _password.text,
        confirmation: _confirm.text,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: Text(
            widget.activation ? 'تم تفعيل حسابك' : 'تم تغيير كلمة المرور',
          ),
          content: const Text('سجل الدخول برقم الهاتف وكلمة المرور الجديدة.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('تسجيل الدخول'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on PartnerAuthFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PartnerAuthScaffold(
    title: widget.activation ? 'إنشاء كلمة المرور' : 'كلمة مرور جديدة',
    description: 'تم تأكيد بريدك. اختر كلمة مرور من ٨ أحرف على الأقل.',
    children: [
      Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _password,
              obscureText: true,
              enabled: !_busy,
              maxLength: 72,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(
                labelText: 'كلمة المرور',
                counterText: '',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) =>
                  (v ?? '').length < 8 ? 'استخدم ٨ أحرف على الأقل' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'تأكيد كلمة المرور',
                prefixIcon: Icon(Icons.lock_reset),
              ),
              validator: (v) =>
                  v != _password.text ? 'كلمتا المرور غير متطابقتين' : null,
            ),
            PartnerAuthError(_error),
            const SizedBox(height: 24),
            PartnerAuthButton(
              label: widget.activation ? 'تفعيل الحساب' : 'حفظ كلمة المرور',
              onPressed: _submit,
              busy: _busy,
            ),
          ],
        ),
      ),
    ],
  );
}
