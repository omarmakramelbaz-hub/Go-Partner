import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

import '../helpers/hive/hive_methods.dart';
import '../helpers/networking/urls.dart';
import '../go_services/service_api.dart';

class StoreApi {
  StoreApi({Dio? dio, String? baseUrl, String? Function()? token})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 40),
            ),
          ),
      _base = (baseUrl ?? Urls.baseUrl).replaceAll(RegExp(r'/+$'), ''),
      _token = token ?? HiveMethods.getToken;
  final Dio _dio;
  final String _base;
  final String? Function() _token;

  Future<Map<String, dynamic>> request(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    final token = _token();
    if (token == null || token.isEmpty)
      throw const ServiceFailure('سجل الدخول للمتابعة / Please sign in.', 401);
    try {
      final response = await _dio.request<dynamic>(
        '$_base/go-stores/$path',
        data: body,
        queryParameters: query,
        options: Options(
          method: body == null ? 'GET' : 'POST',
          validateStatus: (_) => true,
          followRedirects: false,
          headers: {
            'Accept': 'application/json',
            'X-App-Scope': 'go_partner',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      final raw = response.data;
      if (response.statusCode != 200 ||
          raw is! Map ||
          raw['status'] != 'Success' ||
          raw['data'] is! Map) {
        throw ServiceFailure(
          raw is Map
              ? raw['message']?.toString() ?? 'تعذر الحفظ / Could not save.'
              : 'تعذر الاتصال / Connection failed.',
          response.statusCode,
        );
      }
      return Map<String, dynamic>.from(raw['data'] as Map);
    } on DioException {
      throw const ServiceFailure(
        'تعذر الاتصال. أعد المحاولة / Connection failed. Please retry.',
      );
    }
  }

  Future<Map<String, dynamic>> catalog({int page = 1, String search = ''}) =>
      request('catalog', query: {'page': page, 'search': search});
  Future<Map<String, dynamic>> saveStore(Map<String, dynamic> store) =>
      request('profile', body: store);
  Future<Map<String, dynamic>> saveProduct(
    Map<String, dynamic> product, {
    int? id,
    XFile? image,
  }) async {
    final fields = Map<String, dynamic>.from(product);
    fields['options'] = jsonEncode(fields['options']);
    fields['available'] = fields['available'] == true ? '1' : '0';
    if (image != null) {
      final bytes = await image.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024)
        throw const ServiceFailure(
          'حجم الصورة أكبر من 5 ميجا / Image exceeds 5 MB.',
        );
      final filename = image.name.trim().isEmpty ? 'product.jpg' : image.name;
      final ext = filename.split('.').last.toLowerCase();
      final subtype = ext == 'png'
          ? 'png'
          : ext == 'webp'
          ? 'webp'
          : 'jpeg';
      fields['image'] = MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: MediaType('image', subtype),
      );
    }
    return request(
      id == null ? 'products' : 'products/$id',
      body: FormData.fromMap(fields),
    );
  }

  void close() => _dio.close();
}

String? storePrice(String value) {
  var input = value.trim().replaceAll('٫', '.');
  for (var i = 0; i < 10; i++) {
    input = input
        .replaceAll('٠١٢٣٤٥٦٧٨٩'[i], '$i')
        .replaceAll('۰۱۲۳۴۵۶۷۸۹'[i], '$i');
  }
  if (!RegExp(r'^\d{1,7}(\.\d{1,2})?$').hasMatch(input)) return null;
  final parts = input.split('.');
  final cents =
      int.parse(parts[0]) * 100 +
      int.parse(parts.length == 1 ? '0' : parts[1].padRight(2, '0'));
  if (cents < 1 || cents > 100000000) return null;
  return '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
}

String storeKind(String? value, bool ar) =>
    const {
      'supermarket': ['سوبر ماركت', 'Supermarket'],
      'restaurant': ['مطعم', 'Restaurant'],
      'pharmacy': ['صيدلية', 'Pharmacy'],
    }[value]?[ar ? 0 : 1] ??
    (ar ? 'متجر' : 'Store');
