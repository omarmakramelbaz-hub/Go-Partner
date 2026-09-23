import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'partner_email_verification_screen.dart';
import 'partner_password_screen.dart';

import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/networking/urls.dart';

class PartnerApplicationScreen extends StatefulWidget {
  const PartnerApplicationScreen({super.key, this.partnerType = 'profession'});
  final String partnerType;

  @override
  State<PartnerApplicationScreen> createState() =>
      _PartnerApplicationScreenState();
}

class _PartnerApplicationScreenState extends State<PartnerApplicationScreen> {
  static const _orange = Color(0xFFFD7201);
  static const _navy = Color(0xFF171A1F);
  static const _muted = Color(0xFF7D8490);
  static const _bg = Color(0xFFF7F8FA);

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _payment = TextEditingController();
  final _picker = ImagePicker();

  XFile? _photo;
  String? _profession;
  String _paymentMethod = 'vodafone_cash';
  int _radius = 5;
  double? _lat;
  double? _lng;
  bool _terms = false;
  bool _busy = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    if (widget.partnerType == 'delegate') _profession = 'delivery_courier';
    if (widget.partnerType == 'vendor') _profession = 'store_owner';
  }

  static const _professions = <Map<String, String>>[
    {'key': 'delivery_courier', 'title': 'مندوب توصيل'},
    {'key': 'store_owner', 'title': 'صاحب مطعم أو متجر'},
    {'key': 'appliance_technician', 'title': 'فني صيانة ثلاجات وغسالات'},
    {'key': 'plumber', 'title': 'سباك'},
    {'key': 'painter', 'title': 'نقاش'},
    {'key': 'tile_installer', 'title': 'فني تركيب بلاط'},
    {'key': 'marble_installer', 'title': 'فني تركيب رخام'},
    {'key': 'blacksmith', 'title': 'حداد'},
    {'key': 'electrician', 'title': 'كهربائي'},
    {'key': 'satellite_technician', 'title': 'فني تركيب وصيانة الدش'},
    {'key': 'furniture_carpenter', 'title': 'نجار أثاث'},
    {'key': 'ac_technician', 'title': 'فني تكييف'},
    {'key': 'construction_worker', 'title': 'عامل بناء'},
    {'key': 'auto_mechanic', 'title': 'ميكانيكي سيارات'},
    {'key': 'auto_electrician', 'title': 'كهربائي سيارات'},
    {'key': 'mens_barber', 'title': 'كوافير رجالي'},
    {'key': 'womens_hairdresser', 'title': 'كوافيرة سيدات'},
    {'key': 'tailor', 'title': 'خياط'},
    {'key': 'male_cleaner', 'title': 'عامل نظافة'},
    {'key': 'female_cleaner', 'title': 'عاملة نظافة'},
  ];

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _phone.dispose();
    _email.dispose();
    _payment.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
    );
    if (image != null && mounted) setState(() => _photo = image);
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _show('فعّل إذن الموقع حتى نحدد نطاق عملك.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _lat = position.latitude;
          _lng = position.longitude;
        });
      }
    } catch (_) {
      if (mounted)
        _show('تعذر تحديد الموقع. تأكد من تشغيل خدمة الموقع وحاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photo == null) {
      _show('أضف صورة شخصية واضحة.');
      return;
    }
    if (_profession == null) {
      _show('اختر المهنة.');
      return;
    }
    if (_lat == null || _lng == null) {
      _show('حدد موقعك الحالي.');
      return;
    }
    if (!_terms) {
      _show('وافق على شروط وأحكام الانضمام.');
      return;
    }

    setState(() => _busy = true);
    try {
      final proof = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => PartnerEmailVerificationScreen(
            mobile: _phone.text.trim(),
            email: _email.text.trim(),
            purpose: 'application',
          ),
        ),
      );
      if (!mounted || proof == null) return;
      final bytes = await _photo!.readAsBytes();
      final body = FormData.fromMap({
        'photo': MultipartFile.fromBytes(
          bytes,
          filename: _photo!.name.isEmpty ? 'partner.jpg' : _photo!.name,
        ),
        'email': _email.text.trim().toLowerCase(),
        'email_verification_token': proof,
        'source_app': 'go',
        'partner_type': widget.partnerType,
        'full_name': _name.text.trim(),
        'age': int.parse(_age.text.trim()),
        'profession_key': _profession,
        'lat': _lat,
        'lng': _lng,
        'mobile': _phone.text.trim(),
        'payment_method': _paymentMethod,
        'payment_identifier': _payment.text.trim(),
        'work_radius_km': _radius,
        'terms_accepted': 1,
      });

      final response = await ApiHelper.instance.post(
        Urls.partnerApplications,
        body: body,
        hasToken: false,
      );

      if (!mounted) return;
      if (response.state == ResponseState.complete) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                PartnerApplicationSubmittedScreen(mobile: _phone.text.trim()),
          ),
        );
      } else {
        _show(
          response.data is Map
              ? response.data['message']?.toString() ?? 'تعذر إرسال الطلب.'
              : 'تعذر إرسال الطلب.',
        );
      }
    } catch (_) {
      if (mounted) _show('تعذر إرسال الطلب. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: _orange),
    filled: true,
    fillColor: const Color(0xFFFAFBFC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(17),
      borderSide: const BorderSide(color: Color(0xFFE1E5E8)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(17),
      borderSide: const BorderSide(color: Color(0xFFE1E5E8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(17),
      borderSide: const BorderSide(color: _orange, width: 1.4),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'طلب الانضمام إلى شركاء GO',
            style: TextStyle(color: _navy, fontWeight: FontWeight.w900),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
              children: [
                _hero(),
                const SizedBox(height: 14),
                _card(
                  title: 'البيانات الشخصية',
                  icon: Icons.person_outline_rounded,
                  child: Column(
                    children: [
                      InkWell(
                        onTap: _pickPhoto,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3EA),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFFFD4B8)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  _photo == null
                                      ? Icons.add_a_photo_outlined
                                      : Icons.check_circle_rounded,
                                  color: _photo == null
                                      ? _orange
                                      : Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _photo == null
                                      ? 'أضف صورة شخصية'
                                      : 'تم اختيار الصورة — اضغط لتغييرها',
                                  style: const TextStyle(
                                    color: _navy,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _name,
                        decoration: _dec('الاسم بالكامل', Icons.badge_outlined),
                        validator: (v) => v == null || v.trim().length < 3
                            ? 'اكتب الاسم بالكامل'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _age,
                        keyboardType: TextInputType.number,
                        decoration: _dec('السن', Icons.cake_outlined),
                        validator: (v) {
                          final value = int.tryParse(v ?? '');
                          return value == null || value < 18 || value > 75
                              ? 'السن يجب أن يكون بين 18 و75 سنة'
                              : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textDirection: TextDirection.ltr,
                        decoration: _dec(
                          'البريد الإلكتروني (Gmail أو غيره)',
                          Icons.email_outlined,
                        ),
                        validator: (v) =>
                            !RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch((v ?? '').trim())
                            ? 'اكتب بريدًا إلكترونيًا صحيحًا لاستقبال كود التأكيد'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: _dec('رقم الهاتف', Icons.phone_outlined),
                        validator: (v) =>
                            v == null ||
                                v.replaceAll(RegExp(r'\D'), '').length < 10
                            ? 'اكتب رقم هاتف صحيح'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  title: 'المهنة ونطاق العمل',
                  icon: Icons.handyman_outlined,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _profession,
                        isExpanded: true,
                        decoration: _dec(
                          'اختر المهنة',
                          Icons.work_outline_rounded,
                        ),
                        items: _professions
                            .where(
                              (p) => widget.partnerType == 'profession'
                                  ? ![
                                      'delivery_courier',
                                      'store_owner',
                                    ].contains(p['key'])
                                  : p['key'] == _profession,
                            )
                            .map(
                              (p) => DropdownMenuItem(
                                value: p['key'],
                                child: Text(p['title']!),
                              ),
                            )
                            .toList(),
                        onChanged: widget.partnerType == 'profession'
                            ? (value) => setState(() => _profession = value)
                            : null,
                      ),
                      const SizedBox(height: 13),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _locating ? null : _locate,
                          icon: _locating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _lat == null
                                      ? Icons.my_location_rounded
                                      : Icons.check_circle_rounded,
                                ),
                          label: Text(
                            _lat == null
                                ? 'تحديد موقعي الحالي'
                                : 'تم تحديد الموقع',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _orange,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            side: const BorderSide(color: Color(0xFFFFCBA9)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'المسافة التي يمكنك العمل داخلها',
                          style: TextStyle(
                            color: _navy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [5, 10, 15, 20]
                            .map(
                              (km) => ChoiceChip(
                                label: Text('$km كم'),
                                selected: _radius == km,
                                selectedColor: _orange,
                                labelStyle: TextStyle(
                                  color: _radius == km ? Colors.white : _navy,
                                  fontWeight: FontWeight.w800,
                                ),
                                onSelected: (_) => setState(() => _radius = km),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  title: 'استلام المستحقات',
                  icon: Icons.account_balance_wallet_outlined,
                  child: Column(
                    children: [
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'vodafone_cash',
                            label: Text('Vodafone Cash'),
                          ),
                          ButtonSegment(
                            value: 'instapay',
                            label: Text('Instapay'),
                          ),
                        ],
                        selected: {_paymentMethod},
                        onSelectionChanged: (value) =>
                            setState(() => _paymentMethod = value.first),
                      ),
                      const SizedBox(height: 13),
                      TextFormField(
                        controller: _payment,
                        keyboardType: TextInputType.phone,
                        decoration: _dec(
                          _paymentMethod == 'vodafone_cash'
                              ? 'رقم محفظة Vodafone Cash'
                              : 'رقم الهاتف / عنوان Instapay',
                          Icons.payments_outlined,
                        ),
                        validator: (v) => v == null || v.trim().length < 5
                            ? 'اكتب بيانات استلام صحيحة'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _termsCard(),
                const SizedBox(height: 18),
                SizedBox(
                  height: 58,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _submit,
                    icon: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _busy ? 'جاري الإرسال...' : 'إرسال طلب الانضمام',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF292D33), Color(0xFF101216)],
      ),
      borderRadius: BorderRadius.circular(26),
    ),
    child: Row(
      children: [
        Container(
          width: 58,
          height: 58,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: SvgPicture.asset(
            'assets/svg/go_partner_logo.svg',
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ابدأ رحلتك مع GO Partner',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'قدّم بياناتك أولاً. بعد مراجعة الإدارة والموافقة يتم تفعيل حسابك لاستقبال الطلبات المتوافقة مع مهنتك ونطاقك.',
                style: TextStyle(color: Color(0xFFC8D6E0), height: 1.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE7EAED)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1E7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _orange),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: _navy,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );

  Widget _termsCard() => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE7EAED)),
    ),
    child: Column(
      children: [
        CheckboxListTile(
          value: _terms,
          onChanged: (value) => setState(() => _terms = value ?? false),
          activeColor: _orange,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'أوافق على شروط وأحكام شركاء GO',
            style: TextStyle(color: _navy, fontWeight: FontWeight.w900),
          ),
          subtitle: const Text(
            'صحة البيانات، الخبرة المهنية، جودة الخدمة، احترام العملاء، استخدام الموقع، وسياسات المنصة والخصوصية.',
            style: TextStyle(color: _muted, height: 1.45),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showTerms,
            child: const Text('عرض الشروط كاملة'),
          ),
        ),
      ],
    ),
  );

  void _showTerms() {
    const terms = [
      'يجب ألا يقل عمر مقدم الخدمة عن 18 عامًا.',
      'يقر مقدم الطلب بأن جميع البيانات والصورة ورقم الهاتف وبيانات الاستلام صحيحة وتخصه.',
      'يلتزم مقدم الخدمة بامتلاك الخبرة المناسبة للمهنة المختارة وبجودة تنفيذ الخدمة.',
      'يوافق مقدم الخدمة على استخدام الموقع لتحديد نطاق استقبال الطلبات والتتبع أثناء تنفيذ الطلب عند تفعيل الميزة.',
      'يلتزم باحترام العميل والمحافظة على ممتلكاته وخصوصيته وعدم استخدام المنصة في نشاط مخالف للقانون.',
      'تطبق العمولات أو رسوم المنصة والأسعار السارية وقت تنفيذ الطلب كما تظهر داخل التطبيق.',
      'يحق لإدارة GO تعليق أو إيقاف الحساب عند تقديم بيانات غير صحيحة أو وجود شكاوى جسيمة أو مخالفة الشروط.',
      'تعالج البيانات اللازمة لتشغيل الحساب وفق سياسة الخصوصية، ولا تعرض بيانات Vodafone Cash أو Instapay للعملاء.',
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'شروط الانضمام إلى شركاء GO',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                ...terms.map(
                  (term) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: _orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            term,
                            style: const TextStyle(height: 1.45, color: _navy),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      setState(() => _terms = true);
                    },
                    style: FilledButton.styleFrom(backgroundColor: _orange),
                    child: const Text('موافق'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PartnerApplicationSubmittedScreen extends StatefulWidget {
  const PartnerApplicationSubmittedScreen({super.key, required this.mobile});

  final String mobile;

  @override
  State<PartnerApplicationSubmittedScreen> createState() =>
      _PartnerApplicationSubmittedScreenState();
}

class _PartnerApplicationSubmittedScreenState
    extends State<PartnerApplicationSubmittedScreen> {
  static const _orange = Color(0xFFFD7201);
  static const _navy = Color(0xFF171A1F);
  static const _muted = Color(0xFF7D8490);

  String _status = 'pending';
  String? _reason;
  String? _professionName;
  bool _checking = false;
  bool _activating = false;
  bool _accountActive = false;
  bool _emailRequired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkStatus());
  }

  String _normalizePhone(String value) {
    var phone = value.replaceAll(RegExp(r'\D'), '');
    if (phone.startsWith('20') && phone.length > 10) {
      phone = phone.substring(2);
    }
    while (phone.startsWith('0')) {
      phone = phone.substring(1);
    }
    return phone;
  }

  Future<void> _checkStatus() async {
    setState(() => _checking = true);
    final response = await ApiHelper.instance.post(
      Urls.partnerApplicationStatus,
      body: FormData.fromMap({'mobile': _normalizePhone(widget.mobile)}),
      hasToken: false,
    );

    if (!mounted) return;

    if (response.state == ResponseState.complete &&
        response.data is Map &&
        response.data['data'] is Map) {
      final data = response.data['data'] as Map;
      final profession = data['profession'];
      setState(() {
        _status = data['status']?.toString() ?? 'pending';
        _accountActive = data['account_active'] == true;
        _emailRequired = data['email_required'] == true;
        _reason = data['decline_reason']?.toString();
        _professionName = profession is Map
            ? profession['ar']?.toString()
            : null;
      });
    } else if (response.data is Map) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.data['message']?.toString() ?? 'تعذر تحديث حالة الطلب.',
          ),
        ),
      );
    }

    if (mounted) setState(() => _checking = false);
  }

  Future<void> _activateAccount() async {
    if (_activating) return;
    setState(() => _activating = true);
    final proof = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => PartnerEmailVerificationScreen(
          mobile: widget.mobile,
          purpose: 'activation',
        ),
      ),
    );
    if (!mounted) return;
    if (proof != null) {
      final success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PartnerPasswordScreen(
            mobile: widget.mobile,
            proof: proof,
            activation: true,
          ),
        ),
      );
      if (!mounted) return;
      if (success == true) {
        Navigator.pop(context);
        return;
      }
    }
    setState(() => _activating = false);
  }

  @override
  Widget build(BuildContext context) {
    final accepted = _status == 'accepted';
    final declined = _status == 'declined';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  accepted
                      ? Icons.verified_rounded
                      : declined
                      ? Icons.cancel_rounded
                      : Icons.schedule_rounded,
                  size: 94,
                  color: accepted
                      ? const Color(0xFF1B9A55)
                      : declined
                      ? Colors.redAccent
                      : _orange,
                ),
                const SizedBox(height: 20),
                Text(
                  accepted
                      ? 'تم قبول طلبك'
                      : declined
                      ? 'لم تتم الموافقة على الطلب'
                      : 'تم استلام طلبك بنجاح',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  accepted
                      ? (_accountActive
                            ? 'حسابك مفعل بالفعل. سجل الدخول برقم الهاتف وكلمة المرور.'
                            : _emailRequired
                            ? 'طلبك قديم ولم يُسجل له بريد مؤكد. تواصل مع الدعم لتحديث بياناتك قبل التفعيل.'
                            : 'تمت الموافقة على طلبك. أكّد بريدك المسجل ثم أنشئ كلمة المرور لتفعيل الحساب.')
                      : declined
                      ? (_reason?.isNotEmpty == true
                            ? 'سبب الرفض: $_reason'
                            : 'يمكنك تحديث بياناتك والتقديم مرة أخرى.')
                      : 'طلبك قيد المراجعة. لن يمكن إنشاء حساب شريك أو استقبال طلبات قبل موافقة الإدارة.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _muted,
                    height: 1.6,
                    fontSize: 15,
                  ),
                ),
                if (_professionName?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    'المهنة: $_professionName',
                    style: const TextStyle(
                      color: _orange,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const SizedBox(height: 26),
                if (accepted && !_accountActive && !_emailRequired) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _activating ? null : _activateAccount,
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text(
                        'إنشاء وتفعيل حساب الشريك',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1B9A55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _checking ? null : _checkStatus,
                    icon: _checking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: const Text(
                      'تحديث حالة الطلب',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('العودة لتسجيل الدخول'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
