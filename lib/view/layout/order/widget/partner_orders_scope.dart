import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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
  StreamSubscription<RemoteMessage>? _messages;
  StreamSubscription<RemoteMessage>? _openedMessages;
  StreamSubscription<List<ConnectivityResult>>? _connectivity;

  @override
  void initState() {
    super.initState();
    _orders = context.read<PartnerOrdersController>();
    _pusher = context.read<PusherController>();
    _pusher.addEventListener('delegate.updated', _onOrder);
    if (!kIsWeb) {
      _messages = FirebaseMessaging.onMessage.listen(_onMessage);
      _openedMessages = FirebaseMessaging.onMessageOpenedApp.listen(_onMessage);
    }
    _connectivity = Connectivity().onConnectivityChanged.listen(
      (connections) {
        if (connections.any((value) => value != ConnectivityResult.none)) {
          _orders.requestLiveRefresh();
        }
      },
      // Polling remains available if the platform cannot report connectivity.
      onError: (Object error) {
        debugPrint('Order connectivity updates unavailable: $error');
      },
    );
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = WidgetsBinding.instance.lifecycleState;
      if (mounted && (state == null || state == AppLifecycleState.resumed)) {
        _orders.startLiveUpdates();
      }
    });
  }

  void _onOrder(PusherEvent event) => _orders.requestLiveRefresh();

  // Fetch the authenticated inbox instead of trusting notification payloads
  // as order data. This includes service requests, not just delivery events.
  void _onMessage(RemoteMessage message) => _orders.requestLiveRefresh();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _orders.startLiveUpdates();
    } else {
      _orders.pauseLiveUpdates();
    }
  }

  @override
  void dispose() {
    _orders.pauseLiveUpdates();
    _messages?.cancel();
    _openedMessages?.cancel();
    _connectivity?.cancel();
    _pusher.removeEventListener('delegate.updated', _onOrder);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
