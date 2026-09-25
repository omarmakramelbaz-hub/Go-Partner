import 'package:dio/dio.dart';

import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/networking/urls.dart';
import '../model/delegate_order_model.dart';
import '../model/partner_order.dart';

typedef OrdersGet =
    Future<ApiResponse> Function(
      String url, {
      Map<String, dynamic>? queryParameters,
    });
typedef OrdersPost = Future<ApiResponse> Function(String url, {dynamic body});

class PartnerOrderPage {
  const PartnerOrderPage(this.items, {this.nextPage});
  final List<PartnerOrder> items;
  final int? nextPage;
}

class PartnerOrdersException implements Exception {
  const PartnerOrdersException(this.message);
  final String? message;
}

class PartnerOrdersRepository {
  PartnerOrdersRepository({OrdersGet? get, OrdersPost? post})
    : _get =
          get ??
          ((url, {queryParameters}) =>
              ApiHelper.instance.get(url, queryParameters: queryParameters)),
      _post =
          post ?? ((url, {body}) => ApiHelper.instance.post(url, body: body));

  final OrdersGet _get;
  final OrdersPost _post;

  dynamic _data(ApiResponse response) {
    if (response.state != ResponseState.complete) {
      throw PartnerOrdersException(
        response.data is Map ? response.data['message']?.toString() : null,
      );
    }
    if (response.data is! Map || !(response.data as Map).containsKey('data')) {
      throw const PartnerOrdersException(null);
    }
    return response.data['data'];
  }

  Future<PartnerOrderPage> delivery(String status, {int page = 1}) async {
    // Do not use home=yes: it excludes accepted orders from previous days.
    final data = _data(
      await _get(
        '${Urls.baseUrl}delegate/orders',
        queryParameters: {'status': status, 'page': page},
      ),
    );
    final raw = data is Map ? data['data'] : data;
    if (raw is! List) throw const PartnerOrdersException(null);
    final meta = data is Map && data['meta'] is Map
        ? data['meta'] as Map
        : const {};
    final last = int.tryParse('${meta['last_page']}') ?? page;
    return PartnerOrderPage(
      raw
          .map(
            (item) => PartnerOrder.delivery(
              DelegateOrdersModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            ),
          )
          .where((order) => order.delivery?.id != null)
          .toList(),
      nextPage: page < last ? page + 1 : null,
    );
  }

  Future<PartnerOrderPage> services({bool history = false}) async {
    final raw = _data(
      await _get(
        Urls.delegateServiceRequests,
        queryParameters: history ? null : {'status': 'current'},
      ),
    );
    if (raw is! List) throw const PartnerOrdersException(null);
    final items = raw
        .map(
          (item) =>
              PartnerOrder.service(Map<String, dynamic>.from(item as Map)),
        )
        .where((item) => int.tryParse('${item.service?['id']}') != null)
        .toList();
    return PartnerOrderPage(
      history ? items.where((item) => item.isClosed).toList() : items,
    );
  }

  Future<void> submitDeliveryOffer(PartnerOrder order, num price) async {
    if (!order.isDelivery || !order.isNew || price <= 0) {
      throw const PartnerOrdersException(null);
    }
    _data(
      await _post(
        Urls.delegateShippingOffer(order.id),
        body: FormData.fromMap({'price': price}),
      ),
    );
  }
  Future<void> reviseDeliveryOffer(PartnerOrder order, num price) async {
    if (!order.isDelivery || !order.isActive || price <= 0) {
      throw const PartnerOrdersException(null);
    }
    _data(
      await _post(
        Urls.reviseShippingOffer(order.id),
        body: FormData.fromMap({'price': price}),
      ),
    );
  }


  Future<void> update(PartnerOrder order, PartnerOrderAction action) async {
    if (!order.allows(action)) throw const PartnerOrdersException(null);
    final String url;
    final dynamic body;
    if (order.source == PartnerOrderSource.service) {
      url = Urls.updateDelegateServiceRequest(order.id);
      body = {
        'status': switch (action) {
          PartnerOrderAction.accept => 'accepted',
          PartnerOrderAction.decline => 'declined',
          PartnerOrderAction.complete => 'completed',
          PartnerOrderAction.pickup => throw const PartnerOrdersException(null),
        },
      };
    } else if (action == PartnerOrderAction.complete) {
      url = '${Urls.compleatOrderDelegate}${order.id}/completed';
      body = null;
    } else {
      url = '${Urls.delegateAcceptDecline}${order.id}';
      body = FormData.fromMap({
        'status': switch (action) {
          PartnerOrderAction.accept => 'accept',
          PartnerOrderAction.decline => 'declined',
          PartnerOrderAction.pickup => 'shipped',
          PartnerOrderAction.complete => throw StateError('Handled above'),
        },
      });
    }
    _data(await _post(url, body: body));
  }
}
