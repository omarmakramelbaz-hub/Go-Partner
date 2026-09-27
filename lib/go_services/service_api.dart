import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../helpers/hive/hive_methods.dart';
import '../helpers/networking/urls.dart';

final goWalletChanges = ValueNotifier<int>(0);

class ServiceFailure implements Exception {
  const ServiceFailure(this.message, [this.status]);
  final String message;
  final int? status;
  @override
  String toString() => message;
}
class ServiceCapabilities {
  const ServiceCapabilities({required this.ready, required this.enabled});
  final bool ready;
  final bool enabled;
  factory ServiceCapabilities.fromMap(Map<String, dynamic> data) => ServiceCapabilities(ready: data['schema_ready'] == true && data['version'] == 1, enabled: data['enabled'] == true);
}

/// Uses the same authentication scope as Go Partner, with no client-side
/// wallet mutations. Commission, availability and assignment remain server-owned.
class ServiceApi {
  ServiceApi({Dio? dio, String? baseUrl, String? Function()? token})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 30), sendTimeout: const Duration(seconds: 30))),
        _base = (baseUrl ?? Urls.baseUrl).replaceAll(RegExp(r'/+$'), ''),
        _token = token ?? HiveMethods.getToken;
  final Dio _dio;
  final String _base;
  final String? Function() _token;
  Future<Map<String, dynamic>> request(String path, {Object? body, Map<String, dynamic>? query, bool public = false}) async {
    final token = _token();
    if (!public && (token == null || token.isEmpty)) throw const ServiceFailure('سجل الدخول للمتابعة / Please sign in.', 401);
    try {
      final response = await _dio.request<dynamic>('$_base/go-services/$path', data: body, queryParameters: query,
        options: Options(method: body == null ? 'GET' : 'POST', followRedirects: false, validateStatus: (_) => true, contentType: 'application/json',
          headers: {'Accept': 'application/json', 'X-App-Scope': 'go_partner', if (!public) 'Authorization': 'Bearer $token'}));
      final raw = response.data;
      if (response.statusCode != 200 && response.statusCode != 201) throw ServiceFailure(raw is Map ? raw['message']?.toString() ?? 'تعذر تنفيذ الطلب / Request failed.' : 'تعذر تنفيذ الطلب / Request failed.', response.statusCode);
      if (raw is! Map || raw['data'] is! Map || raw['status'] != 'Success') throw const ServiceFailure('استجابة غير متوقعة / Invalid response.');
      if (body != null) goWalletChanges.value++;
      return Map<String, dynamic>.from(raw['data'] as Map);
    } on DioException { throw const ServiceFailure('تعذر الاتصال. حدّث حالة الشغلانة قبل إعادة المحاولة / Connection failed. Refresh the job before retrying.'); }
  }
  Future<ServiceCapabilities> capabilities() async {
    try { return ServiceCapabilities.fromMap(await request('capabilities', public: true)); }
    on ServiceFailure catch (error) { if (error.status == 404) return const ServiceCapabilities(ready: false, enabled: false); rethrow; }
  }
  Future<Map<String, dynamic>> walletStatus() => request('wallet-status');
  Future<Map<String, dynamic>> jobs({String scope = 'open', int page = 1}) => request('jobs', query: {'scope': scope, 'page': page});
  Future<Map<String, dynamic>> job(int id) => request('jobs/$id');
  Future<Map<String, dynamic>> quote(int id, Map<String, dynamic> data) => request('jobs/$id/offers', body: data);
  Future<Map<String, dynamic>> skip(int id) => request('jobs/$id/skip', body: <String, dynamic>{});
  Future<Map<String, dynamic>> status(int id, String state, {String? reason, String? cancellationFee}) => request('jobs/$id/status', body: {'status': state, if (reason != null) 'reason': reason, if (cancellationFee != null) 'cancellation_fee': cancellationFee});
  void close() => _dio.close();
}
List<Map<String, dynamic>> serviceMaps(dynamic data) => data is List ? data.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList() : <Map<String, dynamic>>[];
int serviceId(dynamic value) => int.tryParse('$value') ?? 0;
String? normalizeServicePrice(String value) {
  var input = value.trim().replaceAll('٫', '.');
  for (var i = 0; i < 10; i++) { input = input.replaceAll('٠١٢٣٤٥٦٧٨٩'[i], '$i').replaceAll('۰۱۲۳۴۵۶۷۸۹'[i], '$i'); }
  if (!RegExp(r'^\d{1,7}(\.\d{1,2})?$').hasMatch(input)) return null;
  final parts = input.split('.'); final cents = int.parse(parts[0]) * 100 + int.parse(parts.length == 1 ? '0' : parts[1].padRight(2, '0'));
  if (cents < 100 || cents > 100000000) return null;
  return '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
}
bool serviceCanQuote(Map<String, dynamic> job) => job['status'] == 'searching' && job['recipient_status'] == 'invited' && serviceMaps(job['offers']).isEmpty && (DateTime.tryParse('${job['search_until']}')?.isAfter(DateTime.now()) ?? false);
bool serviceSelected(Map<String, dynamic> job) => serviceId(job['accepted_offer_id']) > 0 && serviceMaps(job['offers']).any((offer) => offer['status'] == 'accepted' && serviceId(offer['id']) == serviceId(job['accepted_offer_id']));
String serviceState(String? value, bool ar) {
  const labels = <String, List<String>>{
    'searching': ['بانتظار عروض واتفاق العميل', 'Awaiting quotations and agreement'],
    'booked': ['تم الاتفاق', 'Booked'], 'in_progress': ['جاري التنفيذ', 'In progress'],
    'awaiting_confirmation': ['بانتظار تأكيد العميل للإتمام', 'Awaiting customer completion'],
    'completed': ['مكتمل', 'Completed'], 'cancelled': ['ملغي', 'Cancelled'], 'expired': ['انتهت الصلاحية', 'Expired'],
    'disputed': ['اعتراض قيد المراجعة', 'Dispute under review'], 'offered': ['العرض مرسل للعميل', 'Quote sent'],
    'accepted': ['تم اختيار عرضك', 'Your quote was selected'], 'rejected': ['العميل رفض العرض', 'Customer rejected quote'],
    'closed': ['مغلق', 'Closed'], 'declined': ['تم التخطي', 'Skipped'],
    'unpaid': ['لم يتم تأكيد الدفع', 'Payment not confirmed'], 'held': ['تم تأكيد الدفع وحجز المبلغ', 'Payment verified; funds held'],
    'cash_due': ['كاش عند إتمام العمل', 'Cash due on completion'], 'paid': ['تمت التسوية', 'Settled'],
    'refund_pending': ['استرداد قيد المعالجة', 'Refund pending'], 'refunded': ['تم رد المبلغ', 'Refunded'], 'review': ['الدفع قيد المراجعة', 'Payment under review'],
  };
  return labels[value]?[ar ? 0 : 1] ?? (ar ? 'حالة قيد التحقق' : 'Status pending verification');
}
