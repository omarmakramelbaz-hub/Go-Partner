import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/networking/urls.dart';

class PartnerApplicationScreen extends StatefulWidget {
  const PartnerApplicationScreen({super.key});

  @override
  State<PartnerApplicationScreen> createState() =>
      _PartnerApplicationScreenState();
}

class _PartnerApplicationScreenState extends State<PartnerApplicationScreen> {
  static const _orange = Color(0xFFFD7201);
  static const _navy = Color(0xFF082A4D);
  static const _muted = Color(0xFF7D8490);
  static const _bg = Color(0xFFF7F8FA);

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _phone = TextEditingController();
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

  static const _professions = <Map<String, String>>[
    {'key': 'delivery_courier', 'title': 'مندوب توصيل'},
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
      final bytes = await _photo!.readAsBytes();
      final body = FormData.fromMap({
        'photo': MultipartFile.fromBytes(
          bytes,
          filename: _photo!.name.isEmpty ? 'partner.jpg' : _photo!.name,
        ),
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
            builder: (_) => PartnerApplicationSubmittedScreen(
              mobile: _phone.text.trim(),
            ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
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
                                  color: _photo == null ? _orange : Colors.green,
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
                        decoration:
                            _dec('اختر المهنة', Icons.work_outline_rounded),
                        items: _professions
                            .map(
                              (p) => DropdownMenuItem(
                                value: p['key'],
                                child: Text(p['title']!),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _profession = value),
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
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
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
                                  color:
                                      _radius == km ? Colors.white : _navy,
                                  fontWeight: FontWeight.w800,
                                ),
                                onSelected: (_) =>
                                    setState(() => _radius = km),
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
            colors: [Color(0xFF0E3654), Color(0xFF071724)],
          ),
          borderRadius: BorderRadius.circular(26),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor: Color(0x22FFFFFF),
              child:
                  Icon(Icons.groups_2_rounded, color: Colors.white, size: 30),
            ),
            SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ابدأ كصاحب مهنة على GO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'قدّم بياناتك أولاً. بعد مراجعة الإدارة والموافقة يتم تفعيل حسابك لاستقبال الطلبات المتوافقة مع مهنتك ونطاقك.',
                    style: TextStyle(
                      color: Color(0xFFC8D6E0),
                      height: 1.5,
                    ),
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
  }) =>
      Container(
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
  const PartnerApplicationSubmittedScreen({
    super.key,
    required this.mobile,
  });

  final String mobile;

  @override
  State<PartnerApplicationSubmittedScreen> createState() =>
      _PartnerApplicationSubmittedScreenState();
}

class _PartnerApplicationSubmittedScreenState
    extends State<PartnerApplicationSubmittedScreen> {
  String _status = 'pending';
  String? _reason;
  bool _checking = false;

  Future<void> _checkStatus() async {
    setState(() => _checking = true);
    final response = await ApiHelper.instance.post(
      Urls.partnerApplicationStatus,
      body: {'mobile': widget.mobile},
      hasToken: false,
    );
    if (mounted) {
      if (response.state == ResponseState.complete &&
          response.data is Map &&
          response.data['data'] is Map) {
        final data = response.data['data'] as Map;
        setState(() {
          _status = data['status']?.toString() ?? 'pending';
          _reason = data['decline_reason']?.toString();
        });
      }
      setState(() => _checking = false);
    }
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
                          : const Color(0xFFFD7201),
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
                    color: Color(0xFF082A4D),
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  accepted
                      ? 'تمت الموافقة. بعد إنشاء حسابك من الإدارة يمكنك تسجيل الدخول من الشاشة الرئيسية.'
                      : declined
                          ? (_reason?.isNotEmpty == true
                              ? 'سبب الرفض: $_reason'
                              : 'يمكنك التواصل مع الإدارة لمعرفة سبب الرفض.')
                          : 'طلبك قيد المراجعة. لن يمكن إنشاء حساب شريك أو استقبال طلبات قبل موافقة الإدارة.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF7D8490),
                    height: 1.6,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _checking ? null : _checkStatus,
                    icon: _checking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: const Text(
                      'تحديث حالة الطلب',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFD7201),
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
