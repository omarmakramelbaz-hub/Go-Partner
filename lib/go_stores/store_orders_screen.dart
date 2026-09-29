import 'dart:async';
import 'package:flutter/material.dart';
import '../go_services/service_api.dart';
import '../helpers/networking/sound_notification.dart';
import '../view/custom_widgets/popups/go_popups.dart';
import 'store_api.dart';
import 'store_order_widgets.dart';

class StoreOrdersScreen extends StatefulWidget {
  const StoreOrdersScreen({super.key, this.api, this.onPendingCount, this.alertsEnabled = false});
  final StoreApi? api;
  final ValueChanged<int>? onPendingCount;
  final bool alertsEnabled;
  @override
  State<StoreOrdersScreen> createState() => _StoreOrdersScreenState();
}
class _StoreOrdersScreenState extends State<StoreOrdersScreen> with WidgetsBindingObserver {
  late final StoreApi api = widget.api ?? StoreApi();
  Timer? timer;
  final List<Map<String, dynamic>> orders = [];
  bool history = false, loading = false, foreground = true;
  int page = 1, lastPage = 1, generation = 0;
  String? error;
  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  @override
  void initState() {
    super.initState(); WidgetsBinding.instance.addObserver(this); load();
    timer = Timer.periodic(const Duration(seconds: 5), (_) { if (foreground && !loading && !history) load(); });
  }
  @override
  void dispose() { generation++; timer?.cancel(); WidgetsBinding.instance.removeObserver(this); if (widget.api == null) api.close(); super.dispose(); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { foreground = state == AppLifecycleState.resumed; if (foreground) load(); }
  Future<void> load({bool more = false}) async {
    final request = ++generation;
    setState(() { loading = true; error = null; });
    try {
      final r = await api.orders(history: history, page: more ? page + 1 : 1);
      if (!mounted || request != generation) return;
      final rows = (r['orders'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
      setState(() { if (!more) orders.clear(); orders.addAll(rows); page = r['page'] as int; lastPage = r['last_page'] as int; });
      if (!history) {
        final incoming = orders.where((o) => o['status'] == 'pending').toList();
        widget.onPendingCount?.call(incoming.length);
        if (widget.alertsEnabled) for (final o in incoming) { unawaited(SoundNotification.instance.playSound(key: 'store:${o['id']}')); }
      }
    } catch (e) { if (mounted && request == generation) setState(() => error = '$e'); }
    finally { if (mounted && request == generation) setState(() => loading = false); }
  }
  @override
  Widget build(BuildContext context) => SafeArea(child: Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 10), child: Row(children: [
      const Icon(Icons.receipt_long, color: Color(0xFFFD7201), size: 30), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(ar ? 'طلبات المتجر' : 'Store orders', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        Text(ar ? 'تابع الطلب من الاستلام حتى التسليم' : 'Follow orders from receipt to delivery', style: const TextStyle(color: Color(0xFF717784)))])),
    ])),
    Padding(padding: const EdgeInsets.all(14), child: SegmentedButton<bool>(segments: [
      ButtonSegment(value: false, label: Text(ar ? 'الحالية' : 'Active')), ButtonSegment(value: true, label: Text(ar ? 'السابقة' : 'History'))],
      selected: {history}, onSelectionChanged: (v) { setState(() { history = v.first; orders.clear(); }); load(); })),
    if (loading && orders.isEmpty) const LinearProgressIndicator(),
    Expanded(child: RefreshIndicator(onRefresh: load, child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16), children: [
      if (error != null) ...[Text(error!), TextButton(onPressed: () => load(), child: Text(ar ? 'إعادة المحاولة' : 'Retry'))],
      if (!loading && error == null && orders.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 60), child: Column(children: [
        const Icon(Icons.shopping_bag_outlined, size: 64, color: Color(0xFFFD7201)), const SizedBox(height: 18),
        Text(ar ? 'لا توجد طلبات هنا حاليًا' : 'No orders here yet'), const SizedBox(height: 8),
        Text(ar ? 'الطلبات الجديدة بتظهر تلقائيًا' : 'New orders appear automatically'),
      ])),
      for (final o in orders) Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(contentPadding: const EdgeInsets.all(18),
        title: Text('${o['number']} · ${o['customer_name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${storeState(o['status'], ar)}\n${o['total']} ${ar ? 'ج.م' : 'EGP'} · ${storePayment(o['payment_method'], ar)}'), isThreeLine: true,
        trailing: const Icon(Icons.chevron_right), onTap: () async {
          SoundNotification.instance.acknowledge('store:${o['id']}');
          await Navigator.push(context, MaterialPageRoute(builder: (_) => StoreOrderDetailsScreen(orderId: o['id'] as int, initial: o, api: widget.api)));
          if (mounted) load();
        })),
      if (page < lastPage) TextButton(onPressed: loading ? null : () => load(more: true), child: Text(ar ? 'عرض المزيد' : 'Load more')),
    ]))),
  ]));
}

const storeActionLabels = {'accept': ['قبول وتجهيز', 'Accept & prepare'], 'reject': ['رفض الطلب', 'Decline order'],
  'ready': ['جاهز للاستلام', 'Mark ready'], 'out_for_delivery': ['خرج للتوصيل', 'Out for delivery'], 'complete': ['تم التسليم', 'Confirm delivery']};

class StoreOrderDetailsScreen extends StatefulWidget {
  const StoreOrderDetailsScreen({super.key, required this.orderId, this.initial, this.api});
  final int orderId;
  final Map<String, dynamic>? initial;
  final StoreApi? api;
  @override
  State<StoreOrderDetailsScreen> createState() => _StoreOrderDetailsScreenState();
}
class _StoreOrderDetailsScreenState extends State<StoreOrderDetailsScreen> with WidgetsBindingObserver {
  late final StoreApi api = widget.api ?? StoreApi();
  Map<String, dynamic>? order;
  Timer? timer;
  bool reading = false, busy = false, foreground = true;
  String? error;
  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  @override
  void initState() { super.initState(); order = widget.initial; WidgetsBinding.instance.addObserver(this); refresh(); timer = Timer.periodic(const Duration(seconds: 5), (_) { if (foreground && !busy) refresh(); }); }
  @override
  void dispose() { timer?.cancel(); WidgetsBinding.instance.removeObserver(this); if (widget.api == null) api.close(); super.dispose(); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { foreground = state == AppLifecycleState.resumed; if (foreground) refresh(); }
  Future<void> refresh() async {
    if (reading) return;
    reading = true;
    try { final r = await api.order(widget.orderId); if (mounted && !busy) setState(() { order = Map<String, dynamic>.from(r['order']); error = null; }); }
    catch (e) { if (mounted && !busy) setState(() => error = '$e'); }
    finally { reading = false; }
  }
  Future<void> action(String action) async {
    SoundNotification.instance.acknowledge('store:${widget.orderId}');
    final reason = TextEditingController();
    final form = GlobalKey<FormState>();
    final label = storeActionLabels[action]![ar ? 0 : 1];
    final yes = await showGoDialog<bool>(context: context, builder: (c) => AlertDialog(title: Text(label),
      content: Form(key: form, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (action == 'accept') Text(ar ? 'عمولة التطبيق ${order!['commission']} ج.م (${order!['commission_rate']}%) تُخصم عند القبول.' : 'App commission of ${order!['commission']} EGP (${order!['commission_rate']}%) is charged on acceptance.'),
        if (action == 'complete') Text(order!['payment_method'] == 'cash' ? (ar ? 'تأكد من تسليم الطلب وتحصيل ${order!['total']} ج.م كاش.' : 'Confirm delivery and collection of ${order!['total']} EGP cash.') : (ar ? 'هل تم تسليم الطلب للعميل؟' : 'Has the order been delivered to the customer?')),
        if (action == 'reject') TextFormField(controller: reason, maxLength: 500, maxLines: 2, decoration: InputDecoration(labelText: ar ? 'سبب الرفض' : 'Reason for declining'),
          validator: (v) => v == null || v.trim().isEmpty ? (ar ? 'اكتب السبب' : 'Enter a reason') : null),
        if (action == 'ready' || action == 'out_for_delivery') Text(ar ? 'سيظهر تحديث الحالة للعميل فورًا.' : 'The customer will see the updated order status.'),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: Text(ar ? 'رجوع' : 'Back')), FilledButton(onPressed: () { if (form.currentState!.validate()) Navigator.pop(c, true); }, child: Text(ar ? 'تأكيد' : 'Confirm'))]));
    final reasonText = reason.text.trim(); reason.dispose();
    if (yes != true || !mounted) return;
    setState(() { busy = true; error = null; });
    try {
      final r = await api.orderAction(widget.orderId, action, order!['revision'] as int, reason: action == 'reject' ? reasonText : null);
      if (mounted) setState(() => order = Map<String, dynamic>.from(r['order']));
      goWalletChanges.value++;
    } catch (e) { if (mounted) setState(() => error = '$e'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(ar ? 'تفاصيل طلب المتجر' : 'Store order details')),
    body: order == null && error == null ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: refresh,
      child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(20), children: [
        if (order != null) StoreOrderBody(order: order!, ar: ar, partner: true),
        if (error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 20),
        for (final a in order?['actions'] as List? ?? []) if (storeActionLabels.containsKey(a)) Padding(padding: const EdgeInsets.only(bottom: 12),
          child: FilledButton(onPressed: busy ? null : () => action('$a'), key: ValueKey('store-order-$a'),
            style: FilledButton.styleFrom(backgroundColor: a == 'reject' ? const Color(0xFFB53A32) : const Color(0xFFFD7201), foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)),
            child: Text(storeActionLabels[a]![ar ? 0 : 1]))),
        if (busy) const LinearProgressIndicator(),
      ])));
}
