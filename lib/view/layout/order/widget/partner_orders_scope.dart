import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/partner_orders_controller.dart';

/// Home and the orders tab share one inbox for the signed-in partner.
class PartnerOrdersScope extends StatelessWidget {
  const PartnerOrdersScope({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    final professional =
        profile?.isGoPartner == true &&
        profile?.partnerProfessionKey != null &&
        profile?.partnerProfessionKey != 'delivery_courier';
    return ChangeNotifierProvider(
      key: ValueKey('orders-${profile?.id}-$professional'),
      create: (_) => PartnerOrdersController(isProfessional: professional),
      child: _OrderUpdates(child: child),
    );
  }
}

class _OrderUpdates extends StatefulWidget {
  const _OrderUpdates({required this.child});
  final Widget child;
  @override
  State<_OrderUpdates> createState() => _OrderUpdatesState();
}

class _OrderUpdatesState extends State<_OrderUpdates>
    with WidgetsBindingObserver {
  late final PartnerOrdersController _orders;
  late final PusherController _pusher;
  Timer? _timer;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    _orders = context.read<PartnerOrdersController>();
    _pusher = context.read<PusherController>();
    _pusher.addEventListener('delegate.updated', _onOrder);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _orders.refresh();
    });
    // Service requests currently arrive through notifications rather than
    // delegate.updated. Poll while foregrounded so the shared inbox stays fresh.
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_foreground) _orders.refresh();
    });
  }

  void _onOrder(PusherEvent event) => _orders.refresh();
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _orders.refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pusher.removeEventListener('delegate.updated', _onOrder);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
