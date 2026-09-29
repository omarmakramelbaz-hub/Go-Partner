import '../view/custom_widgets/popups/go_popups.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'service_api.dart';
import '../helpers/networking/sound_notification.dart';

String pst(bool ar, String a, String e) => ar ? a : e;
Widget pcard(Widget child) => Card(margin: const EdgeInsets.symmetric(vertical: 8), child: Padding(padding: const EdgeInsets.all(16), child: child));
Widget ptext(String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Text(value, style: const TextStyle(height: 1.5)));
String ptime(dynamic value) { final date = DateTime.tryParse('$value'); return date == null ? '—' : date.toLocal().toString().substring(0, 16); }

/// Amounts and rates are supplied by the server from the offer/agreement snapshot.
Widget partnerCommission(bool ar, Map<String, dynamic> data, {required String status}) {
  final rate = data['commission_rate']?.toString();
  final amount = data['commission']?.toString();
  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    ptext(pst(ar, 'نسبة خدمة التطبيق: ${rate == null ? '—' : '$rate%'}', 'App service fee rate: ${rate == null ? '—' : '$rate%'}')),
    if (amount != null) ptext(pst(ar, 'قيمة خدمة التطبيق: $amount ج.م', 'App service fee: EGP $amount')),
    ptext(switch (status) {
      'charged' => pst(ar, 'تم الخصم من محفظتك عند قبول العميل. لن تخصم مرة أخرى عند إتمام الطلب.', 'Debited from your wallet on customer acceptance. No second charge at completion.'),
      'refunded' => pst(ar, 'تم رد خدمة التطبيق إلى محفظتك بعد إلغاء الطلب.', 'The app service fee was refunded to your wallet after cancellation.'),
      'pending' => pst(ar, 'تخصم من محفظتك فقط عند قبول العميل لعرضك.', 'Debited from your wallet only when the customer accepts your quote.'),
      'not_charged' => pst(ar, 'لم تخصم خدمة التطبيق لهذا العرض.', 'No app service fee was charged for this quote.'),
      _ => pst(ar, 'حدّث الطلب للتحقق من حالة خصم خدمة التطبيق.', 'Refresh the job to verify the app service fee debit.'),
    }),
  ]);
}
Map<String, dynamic>? jobCommission(Map<String, dynamic> job) {
  if (serviceSelected(job)) return job;
  final offers = serviceMaps(job['offers']);
  return offers.isEmpty ? null : offers.first;
}
String jobCommissionStatus(Map<String, dynamic> job) {
  if (serviceSelected(job)) return job['commission_status']?.toString() ?? 'unconfirmed';
  final offers = serviceMaps(job['offers']);
  return job['status'] == 'searching' && offers.isNotEmpty && offers.first['status'] == 'offered' ? 'pending' : 'not_charged';
}

/// Occupies the existing Customer requests board, not a second service section.
/// Couriers keep their original board; professionals retain legacy access.
class PartnerServiceBoard extends StatefulWidget {
  const PartnerServiceBoard({super.key, required this.ar, required this.legacyBuilder, this.scope = 'open', this.api, this.onChanged, this.onViewAll, this.onIncomingOrder});
  final bool ar;
  final WidgetBuilder legacyBuilder;
  final String scope;
  final ServiceApi? api;
  final VoidCallback? onChanged;
  final VoidCallback? onViewAll;
  final void Function(String key)? onIncomingOrder;
  @override
  State<PartnerServiceBoard> createState() => _PartnerServiceBoardState();
}
class _PartnerServiceBoardState extends State<PartnerServiceBoard> with WidgetsBindingObserver {
  late final ServiceApi api = widget.api ?? ServiceApi();
  ServiceCapabilities? caps;
  List<Map<String, dynamic>> jobs = [];
  int? next;
  int pages = 1;
  Set<String>? knownInvitations;
  String? rate;
  String? balance;
  String? error;
  bool loading = false;
  bool foreground = true;
  Timer? timer;
  String t(String a, String e) => pst(widget.ar, a, e);
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); load(); timer = Timer.periodic(const Duration(seconds: 15), (_) { if (mounted && foreground && TickerMode.of(context) && (ModalRoute.of(context)?.isCurrent ?? true)) load(); }); }
  @override
  void didUpdateWidget(covariant PartnerServiceBoard oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.scope != widget.scope) { pages = 1; jobs = []; knownInvitations = null; load(); } }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { foreground = state == AppLifecycleState.resumed; if (foreground) load(); }
  Future<void> load({bool more = false}) async {
    if (loading || (more && next == null)) return;
    final scope = widget.scope;
    final requested = more ? next! : 1;
    setState(() => loading = true);
    try {
      final capabilities = await api.capabilities();
      if (!capabilities.ready) { if (mounted) setState(() { caps = capabilities; error = null; }); return; }
      var page = await api.jobs(scope: scope, page: requested);
      final items = serviceMaps(page['items']); var loaded = requested;
      while (!more && page['next_page'] != null && loaded < pages) { page = await api.jobs(scope: scope, page: serviceId(page['next_page'])); items.addAll(serviceMaps(page['items'])); loaded++; }
      if (!mounted || widget.scope != scope) return;
      final changedBalance = balance != null && balance != page['balance']?.toString();
      setState(() { caps = capabilities; jobs = more ? [...jobs, ...items] : items; pages = loaded; next = page['next_page'] == null ? null : serviceId(page['next_page']); balance = page['balance']?.toString(); rate = page['commission_rate']?.toString(); error = null; });
      final invitations = jobs.where((job) => job['status'] == 'searching' && job['recipient_status'] == 'invited').map((job) => 'job:${job['id']}').toSet();
      final previous = knownInvitations;
      knownInvitations = invitations;
      if (previous != null && foreground && TickerMode.of(context) && (ModalRoute.of(context)?.isCurrent ?? true)) {
        for (final key in invitations.difference(previous)) {
          if (widget.onIncomingOrder != null) { widget.onIncomingOrder!(key); }
          else { SoundNotification.instance.playSound(key: key); }
        }
      }
      if (changedBalance) widget.onChanged?.call();
    } catch (e) { if (mounted && scope == widget.scope) setState(() => error = '$e'); }
    finally { if (mounted) { setState(() => loading = false); if (scope != widget.scope) load(); } }
  }
  Future<void> open(Map<String, dynamic> job) async {
    SoundNotification.instance.acknowledge('job:${job["id"]}');
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PartnerServiceJobScreen(api: api, ar: widget.ar, id: serviceId(job['id']), rate: rate)));
    if (mounted) { widget.onChanged?.call(); await load(); }
  }
  @override
  void dispose() { timer?.cancel(); WidgetsBinding.instance.removeObserver(this); if (widget.api == null) api.close(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (caps?.ready == false) return Directionality(
      textDirection: widget.ar ? TextDirection.rtl : TextDirection.ltr,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        pcard(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(t('عروض المصنعية غير متاحة حاليًا', 'Labour quotations are currently unavailable'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
          ptext(t('عند إتاحتها، هتراجع وصف الشغلانة وترسل عرضك. العمولة تخصم بعد قبول العميل فقط.', 'When available, review the job and send your quote. Commission is charged only after customer acceptance.')),
          if (error != null) ptext(error!),
          TextButton(onPressed: loading ? null : () => load(), child: Text(t('تحديث حالة العروض', 'Check quotation availability'))),
        ])),
        widget.legacyBuilder(context),
      ]),
    );
    return Directionality(textDirection: widget.ar ? TextDirection.rtl : TextDirection.ltr, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Expanded(child: Text(t('طلبات العملاء', 'Customer requests'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 21))), if (widget.onViewAll != null) TextButton(onPressed: widget.onViewAll, child: Text(t('عرض الكل', 'View all')))]),
      ptext(t('راجع الشغلانة وقدّم عرض مصنعية نهائي. العمولة تخصم بعد اختيار العميل لعرضك فقط.', 'Review each job and quote the final labour price. Commission is charged only when the customer selects your quote.')),
      if (balance != null) ptext(t('رصيد المحفظة: $balance ج.م · نسبة خدمة التطبيق: ${rate ?? '—'}%', 'Wallet: EGP $balance · App service fee rate: ${rate ?? '—'}%')),
      if (loading && caps == null) const LinearProgressIndicator(),
      if (error != null) pcard(Column(children: [Text(error!), Text(t('البيانات قد تكون قديمة حتى نجاح التحديث.', 'Information may be stale until refreshed.')), TextButton(onPressed: loading ? null : () => load(), child: Text(t('إعادة المحاولة', 'Retry')))])),
      if (caps != null && !caps!.enabled) ptext(t('عروض جديدة متوقفة مؤقتًا، لكن متابعة الحجوزات القائمة متاحة.', 'New quotes are paused; existing bookings remain available.')),
      if (caps != null && jobs.isEmpty && error == null) pcard(Text(t('لا توجد شغلانات في هذه القائمة حاليًا.', 'No jobs in this list yet.'))),
      for (final job in jobs) pcard(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('#${job['id']} · ${serviceState(job['status']?.toString(), widget.ar)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        ptext('${job['description'] ?? ''}'),
        if (jobCommission(job) != null) partnerCommission(widget.ar, jobCommission(job)!, status: jobCommissionStatus(job)),
        if (job['recipient_status'] == 'quoted' && job['status'] == 'searching') ptext(t('أرسلت عرضك — بانتظار اختيار العميل', 'Quote sent — awaiting customer selection')),
        FilledButton(onPressed: () => open(job), child: Text(t('تفاصيل الشغلانة وعرضي', 'Job details and my quote'))),
      ])),
      if (next != null) TextButton(onPressed: loading ? null : () => load(more: true), child: Text(t('عرض المزيد', 'Load more'))),
      if (caps?.ready == true) legacyRequestsButton(),
    ]));
  }
  Widget legacyRequestsButton() => TextButton(
    onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) => Scaffold(
      appBar: AppBar(title: Text(t('الطلبات السابقة للنظام الجديد', 'Legacy requests'))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: widget.legacyBuilder(context)),
    ))),
    child: Text(t('عرض الطلبات المسجلة بالنظام السابق', 'View requests in the previous system')),
  );
}

class PartnerServiceJobScreen extends StatefulWidget {
  const PartnerServiceJobScreen({super.key, required this.api, required this.ar, required this.id, this.rate});
  final ServiceApi api;
  final bool ar;
  final int id;
  final String? rate;
  @override
  State<PartnerServiceJobScreen> createState() => _PartnerServiceJobScreenState();
}
class _PartnerServiceJobScreenState extends State<PartnerServiceJobScreen> with WidgetsBindingObserver {
  Map<String, dynamic>? job;
  ServiceCapabilities? caps;
  bool reading = false;
  bool busy = false;
  bool stale = true;
  bool foreground = true;
  int revision = 0;
  String? error;
  Timer? timer;
  String t(String a, String e) => pst(widget.ar, a, e);
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); load(); timer = Timer.periodic(const Duration(seconds: 10), (_) { if (foreground && mounted && (ModalRoute.of(context)?.isCurrent ?? true)) load(); }); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { foreground = state == AppLifecycleState.resumed; if (foreground) load(); }
  Future<void> load() async {
    if (reading || busy) return;
    reading = true; final epoch = revision;
    try { final data = await widget.api.job(widget.id); final capabilities = await widget.api.capabilities(); if (mounted && epoch == revision && !busy) setState(() { job = data; caps = capabilities; stale = false; error = null; }); }
    catch (e) { if (mounted && epoch == revision) setState(() { error = '$e'; stale = true; }); }
    finally { reading = false; }
  }
  Future<void> run(Future<Map<String, dynamic>> Function() action) async {
    if (busy || stale) return;
    SoundNotification.instance.acknowledge('job:${widget.id}');
    revision++; setState(() { busy = true; error = null; });
    try { final data = await action(); if (mounted) setState(() { job = data; stale = false; }); }
    catch (e) { if (mounted) setState(() { error = '$e'; stale = true; }); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  void dispose() { timer?.cancel(); WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  Future<bool> confirm(String text) async => await showGoDialog<bool>(context: context, builder: (c) => AlertDialog(title: Text(t('تأكيد', 'Confirm')), content: Text(text), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t('رجوع', 'Back'))), FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(t('تأكيد', 'Confirm')))])) ?? false;
  Future<void> quote() async {
    SoundNotification.instance.acknowledge('job:${widget.id}');
    final data = await showGoDialog<Map<String, dynamic>>(context: context, builder: (_) => PartnerQuoteForm(ar: widget.ar, rate: job?['account_commission_rate']?.toString() ?? widget.rate));
    if (data != null && mounted) await run(() => widget.api.quote(widget.id, data));
  }
  Future<void> state(String value) async {
    SoundNotification.instance.acknowledge('job:${widget.id}');
    String? reason;
    String? cancellationFee;
    if (value == 'cancelled' && job?['status'] == 'booked') {
      final policy = job?['cancellation'];
      if (policy is! Map || policy['fee'] == null) { setState(() => error = t('حدّث الطلب لعرض قيمة الإلغاء أولًا.', 'Refresh the job to load the cancellation fee first.')); return; }
      cancellationFee = policy['fee'].toString();
      if (!await confirm(t('الإلغاء بعد القبول يحمّلك خدمة التطبيق بنسبة ${policy['rate']}%، بقيمة $cancellationFee ج.م. العمولة المخصومة من محفظتك لن تُرد ولن تُخصم مرة ثانية. هل تؤكد الإلغاء؟', 'Cancelling after acceptance makes you responsible for the ${policy['rate']}% app service fee (EGP $cancellationFee). Your existing wallet debit will be retained, with no second charge. Confirm cancellation?'))) return;
    }
    if (value == 'cancelled' || value == 'disputed') { reason = await showGoDialog<String>(context: context, builder: (_) => _ReasonForm(ar: widget.ar)); if (reason == null) return; }
    else if (!await confirm(value == 'in_progress' ? t('تأكيد بدء تنفيذ نطاق العمل المتفق عليه؟', 'Start the agreed work?') : t('سيتم طلب تأكيد إتمام العمل من العميل.', 'The customer will be asked to confirm that the work is complete.'))) return;
    if (mounted) await run(() => widget.api.status(widget.id, value, reason: reason, cancellationFee: cancellationFee));
  }
  Widget button(String label, VoidCallback callback) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: FilledButton(onPressed: busy || stale ? null : callback, child: Text(label)));
  @override
  Widget build(BuildContext context) {
    final data = job; final selected = data != null && serviceSelected(data); final status = data?['status'];
    return Directionality(textDirection: widget.ar ? TextDirection.rtl : TextDirection.ltr, child: Scaffold(appBar: AppBar(title: Text(t('الشغلانة #${widget.id}', 'Job #${widget.id}'))), body: RefreshIndicator(onRefresh: load, child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(18), children: [
      if (busy) const LinearProgressIndicator(),
      if (error != null) pcard(Column(children: [Text(error!), TextButton(onPressed: busy ? null : load, child: Text(t('تحديث الحالة', 'Check status')))])),
      if (data == null && error == null) const Center(child: CircularProgressIndicator()),
      if (data != null) ...[
        Text(serviceState(status?.toString(), widget.ar), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        ptext('${data['description'] ?? ''}'),
        if (data['scheduled_at'] != null) ptext(t('الموعد المطلوب: ${ptime(data['scheduled_at'])}', 'Requested time: ${ptime(data['scheduled_at'])}')),
        if (data['photos'] is List && (data['photos'] as List).isNotEmpty) SizedBox(height: 160, child: ListView(scrollDirection: Axis.horizontal, children: [for (final photo in (data['photos'] as List).whereType<String>()) Padding(padding: const EdgeInsets.all(4), child: InkWell(onTap: () => showGoDialog<void>(context: context, builder: (_) => Dialog(child: InteractiveViewer(child: Image.network(photo, errorBuilder: (_, __, ___) => Text(t('حدّث الشغلانة لتحميل الصور.', 'Refresh the job to load photos.')))))), child: Image.network(photo, width: 160, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 160, child: Icon(Icons.broken_image_outlined)))))])),
        if (data['location'] is Map) pcard(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [ptext('${(data['location'] as Map)['address'] ?? ''}'), if (selected && data['can_contact_customer'] == true && data['phone'] != null) ptext(t('رقم العميل: ${data['phone']}', 'Customer phone: ${data['phone']}')), TextButton(onPressed: () { final p = data['location'] as Map; launchUrl(Uri.https('www.google.com', '/maps', {'q': '${p['lat']},${p['lng']}'}), mode: LaunchMode.externalApplication); }, child: Text(t('افتح موقع التنفيذ', 'Open work location')))])) else ptext(t('العنوان التفصيلي يظهر بعد اختيار عرضك. رقم العميل يظهر بعد قبول عرضك وخصم العمولة.', 'The exact address appears after your quote is selected. Customer contact unlocks after acceptance and commission debit.')),
        if (caps?.enabled == true && serviceCanQuote(data)) button(t('إرسال عرض مصنعية', 'Send labour quote'), quote),
        for (final offer in serviceMaps(data['offers'])) pcard(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(t('عرضي: ${offer['price']} ج.م', 'My quote: EGP ${offer['price']}'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ptext(serviceState(offer['status']?.toString(), widget.ar)), ptext('${offer['scope'] ?? ''}'),
          ptext(offer['materials_included'] == true ? t('الخامات المذكورة مشمولة', 'Specified materials included') : t('مصنعية فقط، بدون خامات', 'Labour only; no materials')),
          ptext(t('الوصول ${offer['arrival_minutes']} دقيقة · العمل ${offer['duration_minutes']} دقيقة', 'Arrival ${offer['arrival_minutes']} min · Work ${offer['duration_minutes']} min')),
          ptext(t('الصلاحية حتى ${ptime(offer['expires_at'])}', 'Valid until ${ptime(offer['expires_at'])}')),
          if (!selected && offer['commission'] != null) partnerCommission(widget.ar, offer, status: jobCommissionStatus(data)),
        ])),
        if (status == 'searching' && ['invited', 'quoted'].contains(data['recipient_status'])) OutlinedButton(onPressed: busy || stale ? null : () async { if (await confirm(t('تخطي الشغلانة وسحب عرضك منها؟', 'Skip this job and withdraw your quote?')) && mounted) await run(() => widget.api.skip(widget.id)); }, child: Text(t('الشغلانة غير مناسبة لي', 'Job is not for me'))),
        if (selected) pcard(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(t('القيمة المتفق عليها: ${data['price']} ج.م', 'Agreed price: EGP ${data['price']}'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ptext(serviceState(data['payment_status']?.toString(), widget.ar)),
          partnerCommission(widget.ar, data, status: jobCommissionStatus(data)),
          if (status == 'cancelled' && data['cancellation'] is Map && (data['cancellation'] as Map)['charged_to'] != null) ptext((data['cancellation'] as Map)['charged_to'] == 'partner' ? t('أنت ألغيت الطلب؛ خدمة التطبيق محسوبة عليك.', 'You cancelled the job; you bear the app service fee.') : t('العميل ألغى الطلب وتحمل خدمة التطبيق؛ تم رد العمولة لمحفظتك.', 'The customer cancelled and bears the app service fee; your commission was refunded.')),
          if (data['payment_status'] == 'unpaid') ptext(t('انتظر تأكيد دفع العميل قبل بدء العمل.', 'Wait for verified customer payment before starting.')),
        ])),
        if (selected && status == 'booked' && ['cash_due', 'held', 'paid'].contains(data['payment_status'])) button(t('بدء الشغل', 'Start work'), () => state('in_progress')),
        if (selected && status == 'in_progress') button(t('أنهيت الشغل — اطلب تأكيد العميل', 'Finished — request customer confirmation'), () => state('awaiting_confirmation')),
        if (selected && status == 'awaiting_confirmation') ptext(t('في انتظار العميل. لا يمكنك إنهاء الطلب نيابة عنه.', 'Waiting for the customer. You cannot confirm completion on their behalf.')),
        if (selected && status == 'booked') OutlinedButton(onPressed: busy || stale ? null : () => state('cancelled'), child: Text(t('إلغاء وتحمل خدمة التطبيق', 'Cancel and bear the app fee'))),
        if (selected && ['in_progress', 'awaiting_confirmation'].contains(status)) OutlinedButton(onPressed: busy || stale ? null : () => state('disputed'), child: Text(t('تسجيل اعتراض', 'Open dispute'))),
        if (status == 'disputed') ptext(t('الاعتراض يحتاج مراجعة الدعم؛ التسوية التلقائية متوقفة.', 'Support review is required; automatic settlement is paused.')),
        if (caps != null && !caps!.enabled) ptext(t('إرسال عروض جديدة متوقف مؤقتًا.', 'New quotations are temporarily paused.')),
      ],
    ]))));
  }
}

class PartnerQuoteForm extends StatefulWidget {
  const PartnerQuoteForm({super.key, required this.ar, this.rate});
  final bool ar;
  final String? rate;
  @override
  State<PartnerQuoteForm> createState() => _PartnerQuoteFormState();
}
class _PartnerQuoteFormState extends State<PartnerQuoteForm> {
  final form = GlobalKey<FormState>(); final price = TextEditingController(); final scope = TextEditingController(); final arrival = TextEditingController(text: '30'); final duration = TextEditingController(text: '60');
  bool materials = false; bool agreed = false;
  String t(String a, String e) => pst(widget.ar, a, e);
  @override
  void dispose() { price.dispose(); scope.dispose(); arrival.dispose(); duration.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(title: Text(t('عرض المصنعية النهائي', 'Final labour quote')), content: SingleChildScrollView(child: Form(key: form, child: Column(mainAxisSize: MainAxisSize.min, children: [
    TextFormField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: t('السعر النهائي بالجنيه', 'Final price in EGP')), validator: (v) => normalizeServicePrice(v ?? '') == null ? t('سعر صحيح من ١ إلى مليون جنيه', 'Valid price from EGP 1 to 1,000,000') : null),
    TextFormField(controller: scope, maxLines: 3, maxLength: 2000, decoration: InputDecoration(labelText: t('تفاصيل الشغل المشمول بالعرض', 'Exact scope included')), validator: (v) => (v?.trim().length ?? 0) < 5 ? t('وضح نطاق الشغل', 'Describe the work') : null),
    SwitchListTile(value: materials, onChanged: (v) => setState(() => materials = v), title: Text(t('السعر يشمل الخامات المذكورة', 'Includes specified materials'))),
    TextFormField(controller: arrival, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t('الوصول خلال (دقيقة)', 'Arrival in minutes')), validator: (v) => (int.tryParse(v ?? '') ?? 0) < 5 || (int.tryParse(v ?? '') ?? 0) > 10080 ? '5–10080' : null),
    TextFormField(controller: duration, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t('مدة العمل (دقيقة)', 'Work duration in minutes')), validator: (v) => (int.tryParse(v ?? '') ?? 0) < 5 || (int.tryParse(v ?? '') ?? 0) > 43200 ? '5–43200' : null),
    ptext(t('عمولة حسابك${widget.rate == null ? '' : ' ${widget.rate}%'} تخصم بعد قبول العميل فقط. يلزم رصيد 50 ج.م لقبول طلب جديد. الرسوم المستحقة قد تجعل الرصيد بالسالب.', 'Your account commission${widget.rate == null ? '' : ' ${widget.rate}%'} is debited only on acceptance. EGP 50 is required for new orders. Due fees may make your balance negative.')),
    ptext(t('بعد قبول العميل، الطرف الذي يلغي يتحمل خدمة التطبيق. إذا ألغيت أنت، لن تُرد العمولة المخصومة.', 'After acceptance, the cancelling party bears the app fee. If you cancel, your commission debit is retained.')),
    CheckboxListTile(value: agreed, onChanged: (v) => setState(() => agreed = v == true), title: Text(t('السعر نهائي لنطاق الشغل المذكور ولا يتغير من طرف واحد.', 'This is a final price for the stated scope; no unilateral changes.'))),
  ]))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t('رجوع', 'Back'))), FilledButton(onPressed: agreed ? () { if (form.currentState!.validate()) Navigator.pop(context, <String, dynamic>{'price': normalizeServicePrice(price.text), 'scope': scope.text.trim(), 'materials_included': materials, 'arrival_minutes': int.parse(arrival.text), 'duration_minutes': int.parse(duration.text)}); } : null, child: Text(t('إرسال العرض', 'Send quote')))]);
}
class _ReasonForm extends StatefulWidget {
  const _ReasonForm({required this.ar}); final bool ar;
  @override
  State<_ReasonForm> createState() => _ReasonFormState();
}
class _ReasonFormState extends State<_ReasonForm> {
  final input = TextEditingController();
  @override
  void dispose() { input.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(title: Text(pst(widget.ar, 'سبب الإجراء', 'Reason')), content: TextField(controller: input, maxLines: 3, maxLength: 500, decoration: InputDecoration(labelText: pst(widget.ar, 'السبب (٣ أحرف على الأقل)', 'Reason (at least 3 characters)'))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(pst(widget.ar, 'رجوع', 'Back'))), FilledButton(onPressed: () { if (input.text.trim().length >= 3) Navigator.pop(context, input.text.trim()); }, child: Text(pst(widget.ar, 'تأكيد', 'Confirm')))]);
}
