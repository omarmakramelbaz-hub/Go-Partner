import 'dart:async';

import 'package:go_partner/view/layout/order/model/delegate_order_model.dart';
import 'package:go_partner/view/layout/order/model/partner_order.dart';
import 'package:go_partner/view/layout/order/service/partner_orders_repository.dart';

PartnerOrder serviceOrder(int id, String status) => PartnerOrder.service({
  'id': id,
  'status': status,
  'profession_key': 'plumber',
  'profession': {'ar': 'صيانة سباكة', 'en': 'Plumbing repair'},
  'customer': {'name': 'عميل تجريبي', 'mobile': '01000000000'},
  'description': 'إصلاح تسريب المياه في المطبخ',
  'location': {
    'address': 'المنصورة، شارع الجمهورية',
    'lat': 31.04,
    'lng': 31.38,
  },
});

PartnerOrder deliveryOrder(int id, String status, {bool waiting = false}) =>
    PartnerOrder.delivery(
      DelegateOrdersModel(
        id: id,
        orderNo: 'GO-$id',
        status: status,
        delegateId: status == 'pending' ? null : 1,
        type: waiting ? 'shipping' : 'current',
        delegateHasStatus: waiting ? 'accepted' : null,
        userName: 'عميل تجريبي',
        resturantName: 'طلب من المطعم',
        resturantLocation: 'شارع الجيش، المنصورة',
        userAddress: UserAddress(address: 'شارع الجمهورية، المنصورة'),
        deliveryPrice: 35,
      ),
    );

class MemoryOrdersRepository extends PartnerOrdersRepository {
  final List<PartnerOrder> items = [];
  final List<String> reads = [];
  final List<String> writes = [];
  bool failServices = false;
  bool failWrite = false;
  bool shippingNeedsConfirmation = false;
  Completer<void>? writeGate;

  @override
  Future<PartnerOrderPage> delivery(String status, {int page = 1}) async {
    reads.add('$status:$page');
    final filtered = items
        .where(
          (item) =>
              item.source == PartnerOrderSource.delivery &&
              switch (status) {
                'current' => item.isActive && !item.awaitingConfirmation,
                'pending' => item.isNew || item.awaitingConfirmation,
                _ => item.isClosed,
              },
        )
        .toList();
    return PartnerOrderPage(
      filtered.skip((page - 1) * 5).take(5).toList(),
      nextPage: page * 5 < filtered.length ? page + 1 : null,
    );
  }

  @override
  Future<PartnerOrderPage> services({bool history = false}) async {
    reads.add(history ? 'serviceHistory' : 'services');
    if (failServices) throw const PartnerOrdersException('offline');
    return PartnerOrderPage(
      items
          .where(
            (item) =>
                item.source == PartnerOrderSource.service &&
                (history ? item.isClosed : !item.isClosed),
          )
          .toList(),
    );
  }

  @override
  Future<void> update(PartnerOrder order, PartnerOrderAction action) async {
    writes.add('${order.key}:${action.name}');
    if (writeGate != null) await writeGate!.future;
    if (failWrite)
      throw const PartnerOrdersException('Request already assigned');
    final status = switch (action) {
      PartnerOrderAction.accept => 'accepted',
      PartnerOrderAction.decline => 'declined',
      PartnerOrderAction.pickup => 'shipped',
      PartnerOrderAction.complete => 'completed',
    };
    final index = items.indexWhere((item) => item.key == order.key);
    items[index] = order.source == PartnerOrderSource.service
        ? serviceOrder(order.id, status)
        : shippingNeedsConfirmation && action == PartnerOrderAction.accept
        ? deliveryOrder(order.id, 'pending', waiting: true)
        : deliveryOrder(order.id, status);
  }
}
