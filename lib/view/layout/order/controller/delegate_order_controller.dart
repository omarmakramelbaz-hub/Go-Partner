// ignore_for_file: unnecessary_getters_setters

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/networking/sound_notification.dart';
import '../../../../helpers/networking/urls.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../model/delegate_order_model.dart';
import '../model/delegate_pagination_model.dart';
import '../screen/delivery_location_screen.dart';

class DelegateOrdersController extends ChangeNotifier {
  void getAllDelegateOrders() {
    Future.wait([getDelegateOngoingOrders(), getDelegateCompletedOrders(), getDelegateWaitingOrders()]);
    notifyListeners();
  }

  void initialDelegateOngoingOrders() {
    _delegateOngoingOrdersResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _delegateOngoingOrders = [];
    _ongoingOrders = null;
    _ongoingOrderPage = 1;
    _onGoingOrdersHasPagination = true;
    _onGoingIsPaginating = false;
    notifyListeners();
  }

  ApiResponse _delegateOngoingOrdersResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get delegateOngoingOrdersResponse => _delegateOngoingOrdersResponse;

  List<DelegateOrdersModel> _delegateOngoingOrders = [];
  List<DelegateOrdersModel> get delegateOngoingOrders => _delegateOngoingOrders;
  DelegateModel? _ongoingOrders;
  DelegateModel? get ongoingOrders => _ongoingOrders;

  int _ongoingOrderPage = 1;
  int get ongoingOrderPage => _ongoingOrderPage;

  set ongoingOrderPage(int value) {
    _ongoingOrderPage = value;
  }

  bool _onGoingOrdersHasPagination = true;
  bool get onGoingOrdersHasPagination => _onGoingOrdersHasPagination;
  bool _onGoingIsPaginating = false;
  bool get onGoingIsPaginating => _onGoingIsPaginating;

  Future<void> getDelegateOngoingOrders({
    int? pageNumber,
    int? orderNo,
    String? delegateFromOut,
    String? type,
    String? date,
  }) async {
    if (_ongoingOrderPage == 1) {
      _delegateOngoingOrdersResponse = ApiResponse(state: ResponseState.loading, data: null);
      _delegateOngoingOrders = [];
      _ongoingOrders = null;
      notifyListeners();
    } else {
      _onGoingIsPaginating = true;
      notifyListeners();
    }
    _delegateOngoingOrdersResponse = await ApiHelper.instance.get(
      Urls.delegateCurrentOrders,
      queryParameters: {
        'page': pageNumber ?? _ongoingOrderPage,
        if (orderNo != null) 'order_no': orderNo,
        if (delegateFromOut != null) 'delegate_from_out': delegateFromOut,
        if (type != null) 'type': type,
        if (date != null && date != '') 'date': date,
      },
    );
    notifyListeners();

    if (_delegateOngoingOrdersResponse.state == ResponseState.complete) {
      Iterable iterable = _delegateOngoingOrdersResponse.data['data']['data'];
      if (_ongoingOrderPage == _delegateOngoingOrdersResponse.data['data']['meta']['last_page']) {
        _onGoingOrdersHasPagination = false;
        // CommonMethods.showToast(message: "No more orders");
        // notifyListeners();
      } else {
        _ongoingOrderPage++;
        _onGoingOrdersHasPagination = true;
        notifyListeners();
      }
      _delegateOngoingOrders.addAll(iterable.map((e) => DelegateOrdersModel.fromJson(e)).toList());

      _ongoingOrders = DelegateModel.fromJson(_delegateOngoingOrdersResponse.data['data']);

      // _DelegateOngoingOrders =
      //     iterable.map((e) => DelegateOrdersModel.fromJson(e)).toList();
      notifyListeners();
    }

    _onGoingIsPaginating = false;
    notifyListeners();
  }

  // ====================================================Completed Orders ============================================================

  void initialDelegateCompletedOrders() {
    _delegateCompletedOrdersResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _delegateCompletedOrders = [];
    _completedOrders = null;
    _completedOrderPage = 1;
    _completedOrdersHasPagination = true;
    _completedIsPaginating = false;
    notifyListeners();
  }

  ApiResponse _delegateCompletedOrdersResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get delegateCompletedOrdersResponse => _delegateCompletedOrdersResponse;

  List<DelegateOrdersModel> _delegateCompletedOrders = [];
  List<DelegateOrdersModel> get delegateCompletedOrders => _delegateCompletedOrders;
  DelegateModel? _completedOrders;
  DelegateModel? get completedOrders => _completedOrders;

  int _completedOrderPage = 1;
  int get completedOrderPage => _completedOrderPage;

  set completedOrderPage(int value) {
    _completedOrderPage = value;
  }

  bool _completedOrdersHasPagination = true;
  bool get completedOrdersHasPagination => _completedOrdersHasPagination;
  bool _completedIsPaginating = false;
  bool get completedIsPaginating => _completedIsPaginating;

  Future<void> getDelegateCompletedOrders({int? pageNumber, int? orderNo}) async {
    if (_completedOrderPage == 1) {
      _delegateCompletedOrdersResponse = ApiResponse(state: ResponseState.loading, data: null);
      _delegateCompletedOrders = [];
      _completedOrders = null;
      notifyListeners();
    } else {
      _completedIsPaginating = true;
      notifyListeners();
    }
    _delegateCompletedOrdersResponse = await ApiHelper.instance.get(
      Urls.delegateCompletedOrders,
      queryParameters: {'page': _completedOrderPage, 'order_no': orderNo},
    );
    notifyListeners();

    if (_delegateCompletedOrdersResponse.state == ResponseState.complete) {
      Iterable iterable = _delegateCompletedOrdersResponse.data['data']['data'];
      if (_completedOrderPage == _delegateCompletedOrdersResponse.data['data']['meta']['last_page']) {
        _completedOrdersHasPagination = false;
      } else {
        _completedOrderPage++;
        _completedOrdersHasPagination = true;
        notifyListeners();
      }
      _delegateCompletedOrders.addAll(iterable.map((e) => DelegateOrdersModel.fromJson(e)).toList());
      _completedOrders = DelegateModel.fromJson(_delegateCompletedOrdersResponse.data['data']);
      notifyListeners();
    }

    _completedIsPaginating = false;
    notifyListeners();
  }

  //=====================================================Single Order ============================================================

  void initialDelegateSingleOrder() {
    _delegateSingleOrderResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _delegateSingleOrder = null;
    notifyListeners();
  }

  ApiResponse _delegateSingleOrderResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get delegateSingleOrderResponse => _delegateSingleOrderResponse;

  DelegateOrdersModel? _delegateSingleOrder;
  DelegateOrdersModel? get delegateSingleOrder => _delegateSingleOrder;

  Future<void> getDelegateSingleOrder({required int id}) async {
    _delegateSingleOrderResponse = ApiResponse(state: ResponseState.loading, data: null);
    notifyListeners();

    _delegateSingleOrderResponse = await ApiHelper.instance.get('${Urls.delegateOrderDetails}$id');
    notifyListeners();

    if (_delegateSingleOrderResponse.state == ResponseState.complete) {
      var data = _delegateSingleOrderResponse.data['data'];

      if (data is Map<String, dynamic>) {
        // If data is a Map, parse it as expected
        _delegateSingleOrder = DelegateOrdersModel.fromJson(data);
      } else if (data is List) {
        // If data is a List, handle it accordingly (e.g., take the first item)
        if (data.isNotEmpty && data.first is Map<String, dynamic>) {
          _delegateSingleOrder = DelegateOrdersModel.fromJson(data.first);
        }
      }
      notifyListeners();
    }
  }

  //==================================================== accept or decline order ============================================================
  Future<void> acceptOrDeclineOrder({
    required int orderId,
    required String status,
    required VoidCallback onSuccess,
  }) async {
    SoundNotification.instance.acknowledge('delivery:$orderId');
    NavigatorMethods.loading();

    FormData body = FormData.fromMap({'status': status});
    final response = await ApiHelper.instance.post('${Urls.delegateAcceptDecline}$orderId', body: body);
    NavigatorMethods.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      onSuccess.call();
      if (status == 'accept') {
        _openAcceptedOrderNavigation(orderId);
      }
      notifyListeners();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  void _openAcceptedOrderNavigation(int orderId) {
    final order = _delegateSingleOrder;
    if (order == null) return;

    final isShipping = order.type == 'shipping';
    final lat = double.tryParse(
      isShipping ? (order.toLat ?? '') : (order.userAddress?.lat ?? ''),
    );
    final lng = double.tryParse(
      isShipping ? (order.toLng ?? '') : (order.userAddress?.lng ?? ''),
    );

    if (lat == null || lng == null || (lat == 0 && lng == 0)) {
      CommonMethods.showError(
        message: 'تعذر تشغيل الملاحة لأن موقع العميل غير متاح.',
      );
      return;
    }

    final addressParts = <String>[
      if (isShipping) order.toAddress ?? '',
      if (!isShipping) order.userAddress?.address ?? '',
      if (!isShipping) order.userAddress?.streetName ?? '',
    ].where((part) => part.trim().isNotEmpty).toList();
    final address = addressParts.join('، ');

    Future.delayed(const Duration(milliseconds: 180), () {
      final context = AppRouters.navigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      Navigator.of(context).pushNamed(
        DeliveryLocationScreen.routeName,
        arguments: DeliveryLocationArgs(
          lat: lat,
          lng: lng,
          address: address,
          orderId: orderId,
          navigationMode: true,
        ),
      );
    });
  }

  //==================================================== complete order ============================================================
  Future<void> completeOrderDelegate({required int orderId, required VoidCallback onSuccess}) async {
    SoundNotification.instance.acknowledge('delivery:$orderId');
    NavigatorMethods.loading();
    final response = await ApiHelper.instance.post('${Urls.compleatOrderDelegate}$orderId/completed');
    NavigatorMethods.loadingOff();
    if (response.state == ResponseState.complete) {
      if (response.data['message'] != null) {
        CommonMethods.showToast(message: response.data['message']);
      }

      onSuccess.call();
      notifyListeners();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  //======================================================
  Future<void> receivedOrderDelegate({required int orderId, required VoidCallback onSuccess}) async {
    SoundNotification.instance.acknowledge('delivery:$orderId');
    NavigatorMethods.loading();

    FormData body = FormData.fromMap({'status': 'shipped'});
    final response = await ApiHelper.instance.post('${Urls.delegateReceivedOrder}$orderId', body: body);
    NavigatorMethods.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      onSuccess.call();
      notifyListeners();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  // =========================================== delegate transfer order price =================================
  Future<void> delegateTransferOrderPrice({required int orderId, required VoidCallback onSuccess}) async {
    SoundNotification.instance.acknowledge('delivery:$orderId');
    NavigatorMethods.loading();

    final response = await ApiHelper.instance.post('${Urls.delegateTransferOrderPrice}$orderId/price');
    NavigatorMethods.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      onSuccess.call();
      notifyListeners();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  //===========================================================

  void addOrderToTop(DelegateOrdersModel delegateOrdersModel) {
    // Check if the order already exists in the list
    final exists = _delegateWaitingOrders.any((order) => order.id == delegateOrdersModel.id);

    if (!exists) {
      updateTotalWaiting((waitingOrders?.meta?.total ?? 0) + 1);
      _delegateWaitingOrders.insert(0, delegateOrdersModel);
      // Update the total count (if required)
      waitingOrders?.meta?.total = (waitingOrders?.meta?.total ?? 0) + 1;
      notifyListeners(); // Notify listeners to update the UI
    } else {
      // log("Order with ID ${delegateOrdersModel.id} already exists.");
    }
  }

  int totalWaiting = 0;

  void updateTotalWaiting(int value) {
    totalWaiting = value;
    notifyListeners(); // Notify the UI to rebuild
  }

  void initialDelegateWaitingOrders() {
    _delegateWaitingOrdersResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _delegateWaitingOrders = [];
    _waitingOrders = null;
    _waitingOrderPage = 1;
    _waitingOrdersHasPagination = true;
    _waitingIsPaginating = false;
    notifyListeners();
  }

  ApiResponse _delegateWaitingOrdersResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get delegateWaitingOrdersResponse => _delegateWaitingOrdersResponse;

  List<DelegateOrdersModel> _delegateWaitingOrders = [];
  List<DelegateOrdersModel> get delegateWaitingOrders => _delegateWaitingOrders;
  DelegateModel? _waitingOrders;
  DelegateModel? get waitingOrders => _waitingOrders;

  int _waitingOrderPage = 1;
  int get waitingOrderPage => _waitingOrderPage;

  set waitingOrderPage(int value) {
    _waitingOrderPage = value;
  }

  bool _waitingOrdersHasPagination = true;
  bool get waitingOrdersHasPagination => _waitingOrdersHasPagination;
  bool _waitingIsPaginating = false;
  bool get waitingIsPaginating => _waitingIsPaginating;

  Future<void> getDelegateWaitingOrders({int? pageNumber, int? orderNo}) async {
    if (_waitingOrderPage == 1) {
      _delegateWaitingOrdersResponse = ApiResponse(state: ResponseState.loading, data: null);
      _delegateWaitingOrders = [];
      _waitingOrders = null;
      notifyListeners();
    } else {
      _waitingIsPaginating = true;
      notifyListeners();
    }
    _delegateWaitingOrdersResponse = await ApiHelper.instance.get(
      Urls.waitingDelegateOrders,
      queryParameters: {'page': pageNumber ?? _waitingOrderPage, if (orderNo != null) 'order_no': orderNo},
    );
    notifyListeners();

    if (_delegateWaitingOrdersResponse.state == ResponseState.complete) {
      Iterable iterable = _delegateWaitingOrdersResponse.data['data']['data'];
      totalWaiting = _delegateWaitingOrdersResponse.data['data']['meta']['total'];
      if (_waitingOrderPage == _delegateWaitingOrdersResponse.data['data']['meta']['last_page']) {
        _waitingOrdersHasPagination = false;
        // CommonMethods.shoWToast(message: "No more orders");
        // notifyListeners();
      } else {
        _waitingOrderPage++;
        _waitingOrdersHasPagination = true;
        notifyListeners();
      }
      _delegateWaitingOrders.addAll(iterable.map((e) => DelegateOrdersModel.fromJson(e)).toList());

      _waitingOrders = DelegateModel.fromJson(_delegateWaitingOrdersResponse.data['data']);

      // _DelegateWaitingOrders =
      //     iterable.map((e) => DelegateOrdersModel.fromJson(e)).toList();
      // notifyListeners();
    }

    _waitingIsPaginating = false;
    notifyListeners();
  }
}
