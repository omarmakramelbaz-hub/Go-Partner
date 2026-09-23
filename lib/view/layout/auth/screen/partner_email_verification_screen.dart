import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../helpers/networking/partner_email_auth.dart';
import '../widget/partner_auth_scaffold.dart';

class PartnerEmailVerificationScreen extends StatefulWidget {
  const PartnerEmailVerificationScreen({
    super.key,
    required this.mobile,
    required this.purpose,
    this.email,
    this.api,
  });
  final String mobile;
  final String purpose;
  final String? email;
  final PartnerEmailAuth? api;
  @override
  State<PartnerEmailVerificationScreen> createState() =>
      _PartnerEmailVerificationScreenState();
}

class _PartnerEmailVerificationScreenState
    extends State<PartnerEmailVerificationScreen> {
  late final _api = widget.api ?? PartnerEmailAuth();
  final _code = TextEditingController();
  PartnerEmailChallenge? _challenge;
  Timer? _timer;
  DateTime _resendAt = DateTime.now();
  int _seconds = 0;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _send();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _cooldown(int seconds) {
    _timer?.cancel();
    _resendAt = DateTime.now().add(Duration(seconds: seconds));
    _seconds = seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(
        () => _seconds = _resendAt
            .difference(DateTime.now())
            .inSeconds
            .clamp(0, seconds),
      );
      if (_seconds == 0) timer.cancel();
    });
  }

  Future<void> _send() async {
    if (_busy || _seconds > 0) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final challenge = await _api.requestCode(
        purpose: widget.purpose,
        mobile: widget.mobile,
        email: widget.email,
      );
      if (!mounted) return;
      setState(() {
        _challenge = challenge;
        _code.clear();
        _cooldown(challenge.resendAfter);
      });
    } on PartnerAuthFailure catch (error) {
      if (mounted)
        setState(() {
          _error = error.message;
          if (error.retryAfter > 0) _cooldown(error.retryAfter);
        });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (_busy || _challenge == null) return;
    if (!RegExp(r'^\d{6}$').hasMatch(_code.text)) {
      setState(() => _error = 'اكتب الكود المكون من ٦ أرقام.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final proof = await _api.verify(_challenge!.id, _code.text);
      if (mounted) Navigator.pop(context, proof);
    } on PartnerAuthFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PartnerAuthScaffold(
    title: 'تأكيد البريد الإلكتروني',
    description: widget.email != null
        ? 'هنرسل كودًا من ٦ أرقام إلى\n${widget.email}'
        : 'لو الحساب مؤهل، هيوصلك كود على البريد المسجل. راجع البريد الوارد والرسائل غير المرغوب فيها.',
    children: [
      const Icon(
        Icons.mark_email_read_outlined,
        size: 54,
        color: Color(0xfffd7201),
      ),
      const SizedBox(height: 22),
      TextField(
        controller: _code,
        enabled: !_busy && _challenge != null,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 6,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 28,
          letterSpacing: 12,
          fontWeight: FontWeight.w800,
        ),
        decoration: const InputDecoration(
          labelText: 'كود تأكيد البريد',
          counterText: '',
        ),
        onSubmitted: (_) => _verify(),
      ),
      PartnerAuthError(_error),
      const SizedBox(height: 18),
      PartnerAuthButton(
        label: 'تأكيد البريد',
        onPressed: _challenge == null ? null : _verify,
        busy: _busy,
      ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: _busy || _seconds > 0 ? null : _send,
        child: Text(
          _seconds > 0 ? 'إعادة الإرسال بعد $_seconds ثانية' : 'إرسال كود جديد',
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'الكود صالح لمدة ١٠ دقائق. التأكيد يثبت ملكية البريد الإلكتروني؛ رقم الهاتف يُستخدم للتواصل وتسجيل الدخول.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xff737b86), height: 1.6, fontSize: 13),
      ),
      if (widget.email == null)
        const Padding(
          padding: EdgeInsets.only(top: 14),
          child: Text(
            'لو حسابك قديم ومفيش بريد مؤكد مسجل، تواصل مع الدعم لتحديث بياناتك.',
            textAlign: TextAlign.center,
          ),
        ),
    ],
  );
}
