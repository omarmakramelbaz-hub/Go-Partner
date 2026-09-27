import 'dart:async';
import 'package:flutter/material.dart';
import 'service_api.dart';

/// Persistent account notice. Existing work and wallet top-ups stay accessible.
class GoWalletShell extends StatefulWidget {
  const GoWalletShell({super.key, required this.child, required this.sessionId, required this.onTopUp, this.api});
  final Widget child;
  final int? sessionId;
  final Future<void> Function() onTopUp;
  final ServiceApi? api;
  @override
  State<GoWalletShell> createState() => _GoWalletShellState();
}
class _GoWalletShellState extends State<GoWalletShell> with WidgetsBindingObserver {
  late final ServiceApi api = widget.api ?? ServiceApi();
  Map<String, dynamic>? wallet;
  Timer? timer;
  bool fetching = false;
  bool foreground = true;
  @override
  void initState() {
    super.initState(); WidgetsBinding.instance.addObserver(this); goWalletChanges.addListener(refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
    timer = Timer.periodic(const Duration(seconds: 15), (_) { if (foreground) refresh(); });
  }
  @override
  void didUpdateWidget(covariant GoWalletShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId) { wallet = null; WidgetsBinding.instance.addPostFrameCallback((_) => refresh()); }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { foreground = state == AppLifecycleState.resumed; if (foreground) refresh(); }
  Future<void> refresh() async {
    final account = widget.sessionId;
    if (!mounted || account == null || fetching) return;
    fetching = true;
    try { final data = await api.walletStatus(); if (mounted && account == widget.sessionId) setState(() => wallet = data); }
    catch (_) { /* Retain the last known warning until a successful refresh. */ }
    finally { fetching = false; if (mounted && account != widget.sessionId && widget.sessionId != null) refresh(); }
  }
  @override
  void dispose() { timer?.cancel(); goWalletChanges.removeListener(refresh); WidgetsBinding.instance.removeObserver(this); if (widget.api == null) api.close(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (widget.sessionId == null || wallet?['can_accept_orders'] != false) return widget.child;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return SafeArea(bottom: false, child: Column(children: [
      Material(color: const Color(0xFFFFF0E1), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFFB74A00)), const SizedBox(width: 9),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ar ? 'يرجى شحن المحفظة لضمان استمرار الخدمة' : 'Please top up your wallet to keep using the service', style: const TextStyle(color: Color(0xFF742F00), fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 4),
          Text(ar ? 'رصيدك: ${wallet!['balance']} ج.م · الحد الأدنى: ${wallet!['minimum_balance']} ج.م' : 'Balance: EGP ${wallet!['balance']} · Minimum: EGP ${wallet!['minimum_balance']}', style: const TextStyle(color: Color(0xFF742F00), fontSize: 12)),
          Text(ar ? 'اشحن ${wallet!['top_up_required']} ج.م لاستقبال طلبات جديدة. متابعة طلباتك القائمة متاحة.' : 'Top up EGP ${wallet!['top_up_required']} for new orders. Existing orders remain accessible.', style: const TextStyle(color: Color(0xFF742F00), fontSize: 12)),
        ])),
        TextButton(onPressed: () async { await widget.onTopUp(); if (mounted) refresh(); }, child: Text(ar ? 'شحن' : 'Top up')),
      ]))),
      Expanded(child: widget.child),
    ]));
  }
}
