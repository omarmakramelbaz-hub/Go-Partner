import 'delegate_order_model.dart';

enum PartnerOrderSource { delivery, service }

enum PartnerOrderAction { accept, decline, pickup, complete }

/// One presentation model; mutations still use each source's existing contract.
class PartnerOrder {
  PartnerOrder.delivery(this.delivery) : service = null;
  PartnerOrder.service(this.service) : delivery = null;

  final DelegateOrdersModel? delivery;
  final Map<String, dynamic>? service;

  PartnerOrderSource get source => delivery != null
      ? PartnerOrderSource.delivery
      : PartnerOrderSource.service;
  int get id => delivery?.id ?? int.parse(service!['id'].toString());
  String get key => '${source.name}:$id';
  String get number => delivery?.orderNo ?? id.toString();
  String get status => delivery?.status ?? service?['status']?.toString() ?? '';
  bool get awaitingConfirmation =>
      delivery != null &&
      const ['pending', 'another_delegate'].contains(status) &&
      const ['accepted', 'accept'].contains(delivery!.delegateHasStatus);
  bool get isNew =>
      const ['pending', 'another_delegate'].contains(status) &&
      (delivery == null || delivery!.delegateHasStatus == null);
  bool get isActive =>
      awaitingConfirmation || const ['accepted', 'shipped'].contains(status);
  bool get isClosed =>
      const [
        'completed',
        'cancelled',
        'declined',
        'new_order',
      ].contains(status) ||
      delivery?.delegateHasStatus == 'declined';
  bool get isCompleted => status == 'completed';
  bool get isDelivery =>
      delivery != null || service?['profession_key'] == 'delivery_courier';
  Map get _customer =>
      service?['customer'] is Map ? service!['customer'] as Map : const {};
  Map get _location =>
      service?['location'] is Map ? service!['location'] as Map : const {};
  String get customer =>
      delivery?.userName ?? _customer['name']?.toString() ?? '';
  String get phone =>
      delivery?.userMobile ?? _customer['mobile']?.toString() ?? '';
  String get description =>
      delivery?.description ?? service?['description']?.toString() ?? '';
  String get pickupAddress => delivery?.type == 'shipping'
      ? delivery?.fromAddress ?? ''
      : delivery?.resturantLocation ?? '';
  String get address => delivery != null
      ? (delivery!.type == 'shipping'
                ? delivery!.toAddress
                : delivery!.userAddress?.address) ??
            ''
      : _location['address']?.toString() ?? '';
  String? get scheduledAt =>
      delivery?.scheduleDate ?? service?['scheduled_at']?.toString();
  List<String> get photos => service?['photos'] is List
      ? (service!['photos'] as List).whereType<String>().toList()
      : const [];
  Uri? get mapUri {
    final lat = double.tryParse(_location['lat']?.toString() ?? '');
    final lng = double.tryParse(_location['lng']?.toString() ?? '');
    if (lat == null ||
        lng == null ||
        !lat.isFinite ||
        !lng.isFinite ||
        lat.abs() > 90 ||
        lng.abs() > 180) {
      return null;
    }
    return Uri.https('www.google.com', '/maps', {'q': '$lat,$lng'});
  }

  String title(bool ar) {
    if (delivery?.resturantName?.trim().isNotEmpty == true) {
      return delivery!.resturantName!;
    }
    final profession = service?['profession'];
    final name = profession is Map
        ? profession[ar ? 'ar' : 'en']?.toString()
        : null;
    return name?.isNotEmpty == true
        ? name!
        : (isDelivery
              ? (ar ? 'طلب توصيل' : 'Delivery order')
              : (ar ? 'طلب خدمة' : 'Service request'));
  }

  String statusLabel(bool ar) {
    if (awaitingConfirmation) {
      return ar ? 'بانتظار تأكيد العميل' : 'Awaiting customer confirmation';
    }
    if (isNew) return ar ? 'طلب جديد' : 'New request';
    if (status == 'accepted') return ar ? 'تم قبول الطلب' : 'Accepted';
    if (status == 'shipped') return ar ? 'جاري التوصيل' : 'Out for delivery';
    if (isCompleted) return ar ? 'مكتمل' : 'Completed';
    if (status == 'declined' || delivery?.delegateHasStatus == 'declined') {
      return ar ? 'مرفوض' : 'Declined';
    }
    if (isClosed) return ar ? 'ملغي' : 'Cancelled';
    return ar ? 'حالة غير متاحة' : 'Status unavailable';
  }

  List<String> steps(bool ar) => delivery != null
      ? (ar
            ? ['قبول الطلب', 'استلام الطلب', 'تم التوصيل']
            : ['Accepted', 'Picked up', 'Delivered'])
      : (ar
            ? ['طلب جديد', 'تم القبول', 'مكتمل']
            : ['Received', 'Accepted', 'Completed']);
  int get step => isCompleted
      ? 2
      : (delivery != null
            ? (status == 'shipped' ? 1 : 0)
            : (status == 'accepted' ? 1 : 0));

  bool allows(PartnerOrderAction action) => switch (action) {
    PartnerOrderAction.accept || PartnerOrderAction.decline => isNew,
    PartnerOrderAction.pickup => delivery != null && status == 'accepted',
    PartnerOrderAction.complete =>
      delivery != null ? status == 'shipped' : status == 'accepted',
  };
}
