import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/networking/urls.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../model/wallet_model.dart';

class WalletController extends ChangeNotifier {
  void initialWallet() {
    _walletResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _wallet = null;
    notifyListeners();
  }

  ApiResponse _walletResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get walletResponse => _walletResponse;
  WalletModel? _wallet;
  WalletModel? get wallet => _wallet;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> getWallet() async {
    if (_disposed || _walletResponse.state == ResponseState.loading) return;
    _walletResponse = ApiResponse(state: ResponseState.loading, data: null);
    notifyListeners();
    final response = await ApiHelper.instance.get(Urls.wallet);
    if (_disposed) return;
    try {
      if (response.state == ResponseState.complete) {
        _wallet = WalletModel.fromJson(Map<String, dynamic>.from(response.data['data']));
      }
      _walletResponse = response;
    } catch (_) {
      _walletResponse = ApiResponse(state: ResponseState.error, data: null);
    }
    notifyListeners();
  }

  String? _selectedPayment;
  String? get selectedPayment => _selectedPayment;
  void setSelectedPayment(String value) {
    _selectedPayment = value;
    notifyListeners();
  }

  //=============>  charging wallet  <================
  Future<void> chargingWallet({required dynamic amount, required Function(String paymentUrl) onSuccess}) async {
    NavigatorMethods.loading();
    try {
      final FormData body = FormData.fromMap({'amount': amount, 'payment_method': _selectedPayment});
      final response = await ApiHelper.instance.post(Urls.chargingWallet, body: body);

      if (response.state == ResponseState.complete) {
        final dynamic payload = response.data;
        final dynamic data = payload is Map ? payload['data'] : null;
        final String link = data is Map ? (data['link']?.toString().trim() ?? '') : '';
        final Uri? uri = link.isEmpty ? null : Uri.tryParse(link);
        final bool validLink =
            uri != null && uri.hasScheme && (uri.scheme.toLowerCase() == 'http' || uri.scheme.toLowerCase() == 'https');

        if (!validLink) {
          final String serverMessage = payload is Map ? (payload['message']?.toString().trim() ?? '') : '';
          CommonMethods.showError(
            message: serverMessage.isNotEmpty ? serverMessage : 'تعذر إنشاء رابط الدفع. حاول مرة أخرى.',
          );
          return;
        }

        final String serverMessage = payload is Map ? (payload['message']?.toString().trim() ?? '') : '';
        if (serverMessage.isNotEmpty) {
          CommonMethods.showToast(message: serverMessage);
        }
        onSuccess.call(link);
      } else {
        final dynamic payload = response.data;
        final String serverMessage = payload is Map ? (payload['message']?.toString().trim() ?? '') : '';
        CommonMethods.showError(
          message: serverMessage.isNotEmpty ? serverMessage : 'تعذر بدء عملية الشحن. حاول مرة أخرى.',
          apiResponse: response,
        );
      }
    } catch (_) {
      CommonMethods.showError(message: 'حدث خطأ أثناء بدء عملية الشحن. حاول مرة أخرى.');
    } finally {
      NavigatorMethods.loadingOff();
    }
  }

  //=============> Mony transfer  <================
  Future<void> checkMonyTransfer({
    required String mobile,
    required num amount,
    required String accountType,
    required VoidCallback onSuccess,
  }) async {
    NavigatorMethods.loading();
    FormData body = FormData.fromMap({'mobile': mobile, 'amount': amount, 'account_type': accountType});
    final response = await ApiHelper.instance.post(Urls.checkMonyTransfer, body: body);
    //  NavigatorMethods.loadingOff();
    if (response.state == ResponseState.complete) {
      onSuccess.call();
      //  CommonMethods.showToast(message: response.data['message']);
    } else {
      NavigatorMethods.loadingOff();
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  Future<void> chargingMonyTransfer({
    required String mobile,
    required num amount,
    required String accountType,
    required VoidCallback onSuccess,
  }) async {
    //  NavigatorMethods.loading();
    FormData body = FormData.fromMap({'mobile': mobile, 'amount': amount, 'account_type': accountType});
    final response = await ApiHelper.instance.post(Urls.transferWallet, body: body);
    NavigatorMethods.loadingOff();
    if (response.state == ResponseState.complete) {
      // CommonMethods.showToast(message: response.data['message']);
      onSuccess.call();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  //==============================================================================

  Future<void> getRedirect() async {
    await ApiHelper.instance.get('https://fasakhaninja.com/api/pament/callback');
    notifyListeners();
  }
}
