import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/networking/urls.dart';

class PartnerOnboardingScreen extends StatefulWidget {
  const PartnerOnboardingScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  State<PartnerOnboardingScreen> createState() => _PartnerOnboardingScreenState();
}

class _PartnerOnboardingScreenState extends State<PartnerOnboardingScreen> {
  static const orange = Color(0xffFD7201);
  static const navy = Color(0xff082A4D);
  static const muted = Color(0xff7D8490);
  static const bg = Color(0xffF7F8FA);

  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final age = TextEditingController();
  final phone = TextEditingController();
  final payout = TextEditingController();
  final picker = ImagePicker();

  XFile? photo;
  String? profession;
  String payoutMethod = 'vodafone_cash';
  int radius = 5;
  double? lat;
  double? lng;
  bool terms = false;
  bool locating = false;
  bool submitting = false;
  bool checking = false;

  static const professions = <Map<String, String>>[
    {'key': 'delivery_courier', 'name': 'مندوب توصيل'},
    {'key': 'appliance_technician', 'name': 'فني صيانة ثلاجات وغسالات'},
    {'key': 'plumber', 'name': 'سباك'},
    {'key': 'painter', 'name': 'نقاش'},
    {'key': 'tile_installer', 'name': 'فني تركيب بلاط'},
    {'key': 'marble_installer', 'name': 'فني تركيب رخام'},
    {'key': 'blacksmith', 'name': 'حداد'},
    {'key': 'electrician', 'name': 'كهربائي'},
    {'key': 'satellite_technician', 'name': 'فني تركيب وصيانة الدش'},
    {'key': 'furniture_carpenter', 'name': 'نجار أثاث'},
    {'key': 'ac_technician', 'name': 'فني تكييف'},
    {'key': 'construction_worker', 'name': 'عامل بناء'},
    {'key': 'auto_mechanic', 'name': 'ميكانيكي سيارات'},
    {'key': 'auto_electrician', 'name': 'كهربائي سيارات'},
    {'key': 'mens_barber', 'name': 'كوافير رجالي'},
    {'key': 'womens_hairdresser', 'name': 'كوافيرة سيدات'},
    {'key': 'tailor', 'name': 'خياط'},
    {'key': 'male_cleaner', 'name': 'عامل نظافة'},
    {'key': 'female_cleaner', 'name': 'عاملة نظافة'},
  ];

  @override
  void dispose() {
    name.dispose();
    age.dispose();
    phone.dispose();
    payout.dispose();
    super.dispose();
  }

  String normalizePhone(String value) {
    var p = value.replaceAll(RegExp(r'\D'), '');
    if (p.startsWith('20') && p.length > 10) p = p.substring(2);
    while (p.startsWith('0')) {
      p = p.substring(1);
    }
    return p;
  }

  void message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> pickPhoto() async {
    final value = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
    );
    if (value != null && mounted) setState(() => photo = value);
  }

  Future<void> useLocation() async {
    setState(() => locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        message('فعّل إذن الموقع لتحديد نطاق عملك.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          lat = position.latitude;
          lng = position.longitude;
        });
      }
    } catch (_) {
      message('تعذر تحديد الموقع. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Future<void> checkStatus() async {
    final mobile = normalizePhone(phone.text);
    if (mobile.length < 10) {
      message('اكتب رقم الهاتف المستخدم في طلب الانضمام أولاً.');
      return;
    }
    setState(() => checking = true);
    try {
      final response = await ApiHelper.instance.post(
        Urls.partnerApplicationStatus,
        body: FormData.fromMap({'mobile': mobile}),
        hasToken: false,
      );
      if (!mounted) return;
      if (response.state != ResponseState.complete) {
        message(response.data is Map
            ? (response.data['message']?.toString() ?? 'لا يوجد طلب بهذا الرقم.')
            : 'لا يوجد طلب بهذا الرقم.');
        return;
      }
      final data = response.data['data'] as Map;
      final status = data['status']?.toString();
      final professionData = data['profession'];
      final professionName = professionData is Map
          ? (professionData['ar']?.toString() ?? '')
          : '';
      if (status == 'accepted') {
        await activateDialog(mobile, professionName);
      } else if (status == 'declined') {
        await statusDialog(
          'تم رفض الطلب',
          data['decline_reason']?.toString().isNotEmpty == true
              ? data['decline_reason'].toString()
              : 'يمكنك تحديث بياناتك وتقديم طلب جديد.',
          Icons.cancel_rounded,
          Colors.red,
        );
      } else {
        await statusDialog(
          'طلبك قيد المراجعة',
          professionName.isEmpty
              ? 'تم استلام طلبك وسيتم تحديث حالته بعد المراجعة.'
              : 'طلبك للانضمام كمقدم خدمة «$professionName» ما زال قيد المراجعة.',
          Icons.hourglass_top_rounded,
          orange,
        );
      }
    } finally {
      if (mounted) setState(() => checking = false);
    }
  }

  Future<void> activateDialog(String mobile, String professionName) async {
    final password = TextEditingController();
    final confirm = TextEditingController();
    final key = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'تم قبول طلب الانضمام',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900, color: navy),
          ),
          content: Form(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (professionName.isNotEmpty)
                  Text(
                    professionName,
                    style: const TextStyle(color: orange, fontWeight: FontWeight.w800),
                  ),
                const SizedBox(height: 10),
                const Text(
                  'أنشئ كلمة مرور لحساب الشريك. الحساب لا يتم إنشاؤه إلا بعد قبول الطلب.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, height: 1.5),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: password,
                  obscureText: true,
                  textDirection: ui.TextDirection.ltr,
                  decoration: decoration('كلمة المرور', Icons.lock_outline_rounded),
                  validator: (v) => (v ?? '').length < 6 ? '6 أحرف على الأقل' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: confirm,
                  obscureText: true,
                  textDirection: ui.TextDirection.ltr,
                  decoration: decoration('تأكيد كلمة المرور', Icons.lock_reset_rounded),
                  validator: (v) => v != password.text ? 'كلمتا المرور غير متطابقتين' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: orange),
              onPressed: () async {
                if (!key.currentState!.validate()) return;
                final response = await ApiHelper.instance.post(
                  Urls.partnerActivate,
                  body: FormData.fromMap({
                    'mobile': mobile,
                    'password': password.text,
                    'password_confirmation': confirm.text,
                  }),
                  hasToken: false,
                );
                if (!dialogContext.mounted) return;
                if (response.state == ResponseState.complete) {
                  Navigator.pop(dialogContext);
                  await statusDialog(
                    'تم تفعيل حسابك',
                    'يمكنك الآن تسجيل الدخول واستقبال الطلبات المتوافقة مع مهنتك ونطاق عملك.',
                    Icons.verified_rounded,
                    Colors.green,
                  );
                  widget.onFinished?.call();
                  if (mounted) Navigator.maybePop(context);
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        response.data is Map
                            ? (response.data['message']?.toString() ?? 'تعذر تفعيل الحساب.')
                            : 'تعذر تفعيل الحساب.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('تفعيل الحساب'),
            ),
          ],
        ),
      ),
    );

    password.dispose();
    confirm.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    if (photo == null) return message('أضف صورة شخصية واضحة.');
    if (profession == null) return message('اختر المهنة.');
    if (lat == null || lng == null) return message('حدد موقعك الحالي أولاً.');
    if (!terms) return message('يجب الموافقة على شروط وأحكام الانضمام.');

    setState(() => submitting = true);
    try {
      final body = FormData.fromMap({
        'photo': MultipartFile.fromBytes(
          await photo!.readAsBytes(),
          filename: photo!.name.isEmpty ? 'partner.jpg' : photo!.name,
        ),
        'full_name': name.text.trim(),
        'age': int.parse(age.text),
        'profession_key': profession,
        'lat': lat,
        'lng': lng,
        'mobile': normalizePhone(phone.text),
        'payment_method': payoutMethod,
        'payment_identifier': payout.text.trim(),
        'work_radius_km': radius,
        'terms_accepted': 1,
      });

      final response = await ApiHelper.instance.post(
        Urls.partnerApplications,
        body: body,
        hasToken: false,
      );
      if (!mounted) return;
      if (response.state == ResponseState.complete) {
        await statusDialog(
          'تم استلام طلبك',
          'طلبك قيد المراجعة. بعد الموافقة ارجع إلى هذه الصفحة واضغط «لدي طلب سابق» لتفعيل الحساب.',
          Icons.task_alt_rounded,
          Colors.green,
        );
        widget.onFinished?.call();
        if (mounted) Navigator.maybePop(context);
      } else {
        message(response.data is Map
            ? (response.data['message']?.toString() ?? 'تعذر إرسال الطلب.')
            : 'تعذر إرسال الطلب.');
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Future<void> statusDialog(
    String title,
    String body,
    IconData icon,
    Color color,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon: Icon(icon, color: color, size: 44),
          title: Text(title, textAlign: TextAlign.center),
          content: Text(body, textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('تمام'),
            ),
          ],
        ),
      ),
    );
  }

  static InputDecoration decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: orange),
      filled: true,
      fillColor: const Color(0xffFAFBFC),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: Color(0xffE0E4E8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: orange, width: 1.4),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(17)),
    );
  }

  Widget section(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffECEFF2)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, 7)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xffFFF1E8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: orange),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      textDirection: keyboard == TextInputType.phone || keyboard == TextInputType.number
          ? ui.TextDirection.ltr
          : ui.TextDirection.rtl,
      decoration: decoration(label, icon),
      validator: validator,
    );
  }

  void showTerms() {
    statusDialog(
      'شروط الانضمام',
      'يجب ألا يقل العمر عن 18 سنة، وأن تكون البيانات والصورة صحيحة. يلتزم الشريك بممارسة المهنة التي يمتلك خبرة بها، وبالتعامل اللائق والمحافظة على خصوصية وممتلكات العملاء، وعدم استخدام المنصة في نشاط مخالف للقانون. يوافق الشريك على استخدام موقعه لتحديد نطاق استقبال الطلبات، وعلى سياسات الأسعار والعمولات، وعلى معالجة البيانات اللازمة لتشغيل الحساب. يحق لإدارة GO تعليق الحساب عند وجود بيانات غير صحيحة أو مخالفات أو شكاوى جسيمة. بيانات Vodafone Cash وInstapay تستخدم للتسويات المالية ولا تعرض للعملاء.',
      Icons.description_outlined,
      orange,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'الانضمام إلى شركاء GO',
            style: TextStyle(color: navy, fontWeight: FontWeight.w900),
          ),
        ),
        body: Form(
          key: formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff102D49), Color(0xff071A2B)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Image.asset('assets/images/go_drive_logo_hd.webp'),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'اشتغل بمهنتك على GO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'قدّم بياناتك، وبعد الموافقة فعّل حسابك وابدأ استقبال الطلبات داخل نطاق عملك.',
                                style: TextStyle(
                                  color: Color(0xffD2DCE5),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: checking ? null : checkStatus,
                        icon: checking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.manage_search_rounded),
                        label: const Text('لدي طلب سابق — تحقق من الحالة'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0x66FFFFFF)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              section('البيانات الشخصية', Icons.person_outline_rounded, [
                InkWell(
                  onTap: pickPhoto,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xffFFF5EE),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          photo == null ? Icons.add_a_photo_outlined : Icons.check_circle_rounded,
                          color: photo == null ? orange : Colors.green,
                          size: 30,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          photo == null ? 'أضف صورة شخصية واضحة' : 'تم اختيار الصورة',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: navy),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                field(name, 'الاسم بالكامل', Icons.badge_outlined,
                    validator: (v) => (v ?? '').trim().length < 3 ? 'اكتب الاسم بالكامل' : null),
                const SizedBox(height: 12),
                field(age, 'السن', Icons.cake_outlined,
                    keyboard: TextInputType.number,
                    validator: (v) {
                      final value = int.tryParse(v ?? '');
                      return value == null || value < 18 || value > 75
                          ? 'السن يجب أن يكون بين 18 و75 سنة'
                          : null;
                    }),
                const SizedBox(height: 12),
                field(phone, 'رقم الهاتف', Icons.phone_outlined,
                    keyboard: TextInputType.phone,
                    validator: (v) => normalizePhone(v ?? '').length < 10 ? 'اكتب رقم هاتف صحيح' : null),
              ]),
              const SizedBox(height: 14),
              section('المهنة ونطاق العمل', Icons.handyman_outlined, [
                DropdownButtonFormField<String>(
                  value: profession,
                  isExpanded: true,
                  decoration: decoration('اختر المهنة', Icons.work_outline_rounded),
                  items: professions
                      .map((p) => DropdownMenuItem(value: p['key'], child: Text(p['name']!)))
                      .toList(),
                  onChanged: (v) => setState(() => profession = v),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: locating ? null : useLocation,
                  icon: Icon(lat == null ? Icons.my_location_rounded : Icons.check_circle_rounded),
                  label: Text(lat == null ? 'تحديد موقعي الحالي' : 'تم تحديد الموقع بنجاح'),
                ),
                const SizedBox(height: 12),
                const Text('المسافة التي يمكنك العمل داخلها',
                    style: TextStyle(fontWeight: FontWeight.w800, color: navy)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [5, 10, 15, 20]
                      .map((km) => ChoiceChip(
                            label: Text('$km كم'),
                            selected: radius == km,
                            onSelected: (_) => setState(() => radius = km),
                            selectedColor: orange,
                            labelStyle: TextStyle(
                              color: radius == km ? Colors.white : navy,
                              fontWeight: FontWeight.w800,
                            ),
                          ))
                      .toList(),
                ),
              ]),
              const SizedBox(height: 14),
              section('استلام المستحقات', Icons.account_balance_wallet_outlined, [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'vodafone_cash', label: Text('Vodafone Cash')),
                    ButtonSegment(value: 'instapay', label: Text('Instapay')),
                  ],
                  selected: {payoutMethod},
                  onSelectionChanged: (v) => setState(() => payoutMethod = v.first),
                ),
                const SizedBox(height: 12),
                field(
                  payout,
                  payoutMethod == 'vodafone_cash'
                      ? 'رقم محفظة Vodafone Cash'
                      : 'رقم الهاتف / عنوان Instapay',
                  Icons.payments_outlined,
                  keyboard: payoutMethod == 'vodafone_cash' ? TextInputType.phone : TextInputType.text,
                  validator: (v) => (v ?? '').trim().length < 5 ? 'اكتب بيانات الاستلام' : null,
                ),
              ]),
              const SizedBox(height: 14),
              CheckboxListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                value: terms,
                activeColor: orange,
                onChanged: (v) => setState(() => terms = v ?? false),
                title: const Text(
                  'أوافق على شروط وأحكام الانضمام كشريك',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: TextButton(
                  onPressed: showTerms,
                  child: const Text('قراءة الشروط والأحكام'),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 58,
                child: FilledButton.icon(
                  onPressed: submitting ? null : submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
                  ),
                  icon: submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    submitting ? 'جاري إرسال الطلب...' : 'إرسال طلب الانضمام',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
