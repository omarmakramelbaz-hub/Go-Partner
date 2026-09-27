import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../helpers/networking/urls.dart';

class StoreSignupFailure implements Exception {
  const StoreSignupFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class SignupImage {
  SignupImage(this.bytes, this.extension);
  final Uint8List bytes;
  final String extension;
  static Future<SignupImage> fromFile(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > 1024 * 1024) {
      throw const StoreSignupFailure('اختر صورة أقل من 1 ميجا.');
    }
    final extension = bytes.length > 3 && bytes[0] == 255 && bytes[1] == 216
        ? 'jpg'
        : bytes.length > 8 &&
              bytes[0] == 137 &&
              bytes[1] == 80 &&
              bytes[2] == 78 &&
              bytes[3] == 71
        ? 'png'
        : bytes.length > 12 &&
              ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
              ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP'
        ? 'webp'
        : null;
    if (extension == null)
      throw const StoreSignupFailure('استخدم صورة JPG أو PNG أو WEBP.');
    return SignupImage(bytes, extension);
  }

  MultipartFile upload(String name) => MultipartFile.fromBytes(
    bytes,
    filename: '$name.$extension',
    contentType: MediaType('image', extension == 'jpg' ? 'jpeg' : extension),
  );
}

class SignupProduct {
  SignupProduct({
    required this.name,
    required this.unit,
    required this.price,
    required this.image,
    this.description = '',
    this.options = const [],
  });
  final String name, unit, price, description;
  final SignupImage image;
  final List<Map<String, String>> options;
  Map<String, dynamic> toJson() => {
    'name': name,
    'unit': unit,
    'price': price,
    'description': description,
    'options': options,
  };
}

class StoreSignupDraft {
  String name = '', address = '';
  String? kind;
  SignupImage? logo;
  final products = <SignupProduct>[];
  int get imageBytes =>
      (logo?.bytes.length ?? 0) +
      products.fold<int>(0, (total, p) => total + p.image.bytes.length);
  String? validate() {
    if (name.trim().length < 2 ||
        address.trim().length < 5 ||
        !signupKinds.containsKey(kind))
      return 'أكمل اسم المتجر ونشاطه وعنوانه.';
    if (logo == null) return 'أضف لوجو المتجر.';
    if (products.isEmpty) return 'أضف منتجًا واحدًا على الأقل.';
    if (products.length > 15)
      return 'يمكن إضافة حتى 15 منتجًا مع طلب الانضمام.';
    return null;
  }

  void attach(FormData body) {
    final error = validate();
    if (error != null) throw StoreSignupFailure(error);
    body.fields.add(
      MapEntry(
        'storefront',
        jsonEncode({
          'name': name.trim(),
          'kind': kind,
          'address': address.trim(),
          'products': products.map((p) => p.toJson()).toList(),
        }),
      ),
    );
    body.files.add(MapEntry('store_logo', logo!.upload('store-logo')));
    for (var i = 0; i < products.length; i++) {
      body.files.add(
        MapEntry('product_images[$i]', products[i].image.upload('product-$i')),
      );
    }
  }
}

const signupKinds = {
  'supermarket': 'سوبر ماركت',
  'restaurant': 'مطعم',
  'pharmacy': 'صيدلية',
};
String? signupPrice(String input) {
  input = input.trim().replaceAll('٫', '.');
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

/// Fresh multipart data on every attempt; public application proofs never enter debug request logs.
class PartnerApplicationApi {
  PartnerApplicationApi({Dio? client, this.scope = 'go_partner'})
    : _client =
          client ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 120),
              receiveTimeout: const Duration(seconds: 60),
            ),
          );
  final Dio _client;
  final String scope;
  Future<void> submit(
    Map<String, dynamic> fields,
    XFile photo, {
    StoreSignupDraft? store,
  }) async {
    final bytes = await photo.readAsBytes();
    if (bytes.length + (store?.imageBytes ?? 0) > 6 * 1024 * 1024) {
      throw const StoreSignupFailure(
        'إجمالي الصور أكبر من 6 ميجا. قلّل حجم الصور أو عدد المنتجات.',
      );
    }
    final body = FormData.fromMap({
      ...fields,
      'photo': MultipartFile.fromBytes(
        bytes,
        filename: photo.name.isEmpty ? 'partner.jpg' : photo.name,
      ),
    });
    store?.attach(body);
    try {
      final result = await _client.post<dynamic>(
        Urls.partnerApplications,
        data: body,
        options: Options(
          followRedirects: false,
          validateStatus: (_) => true,
          headers: {
            'Accept': 'application/json',
            'Lang': 'ar',
            'X-App-Scope': scope,
          },
        ),
      );
      final data = result.data;
      if (result.statusCode != 200 ||
          data is! Map ||
          data['status'] != 'Success') {
        String? message;
        if (data is Map) {
          final errors = data['errors'];
          if (errors is Map &&
              errors.isNotEmpty &&
              errors.values.first is List &&
              (errors.values.first as List).isNotEmpty) {
            message = (errors.values.first as List).first.toString();
          }
          message ??= data['message']?.toString();
        }
        throw StoreSignupFailure(
          message ?? 'تعذر إرسال الطلب. راجع البيانات وحاول مرة أخرى.',
        );
      }
    } on DioException {
      throw const StoreSignupFailure(
        'تعذر الاتصال. بياناتك ما زالت موجودة؛ راجع حالة الطلب قبل إعادة الإرسال.',
      );
    }
  }

  void close() => _client.close();
}
