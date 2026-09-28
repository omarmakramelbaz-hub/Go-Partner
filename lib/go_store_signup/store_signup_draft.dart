import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
  final progress = ValueNotifier<String?>(null);
  String? _uploadToken, _uploadIdentity;
  DateTime? _uploadExpires;
  final _uploaded = <String, SignupImage>{};
  bool hasUploadSession(String mobile, String email) =>
      _uploadToken != null &&
      _uploadIdentity == '$mobile|${email.trim().toLowerCase()}' &&
      _uploadExpires!.isAfter(DateTime.now());
  void clearUploadSession() {
    _uploadToken = null;
    _uploadIdentity = null;
    _uploadExpires = null;
    _uploaded.clear();
  }

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
    if (products.length > 60)
      return 'يمكن إضافة حتى 60 منتجًا مع طلب الانضمام.';
    return null;
  }

  String get catalogJson => jsonEncode({
    'name': name.trim(),
    'kind': kind,
    'address': address.trim(),
    'products': products.map((p) => p.toJson()).toList(),
  });
}

const signupKinds = {
  'supermarket': 'سوبر ماركت',
  'restaurant': 'مطعم',
  'pharmacy': 'صيدلية',
  'clinic': 'عيادات',
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
    if (bytes.length > 5 * 1024 * 1024) {
      throw const StoreSignupFailure('الصورة الشخصية يجب ألا تتجاوز 5 ميجا.');
    }
    if (store != null) {
      final error = store.validate();
      if (error != null) throw StoreSignupFailure(error);
    }
    try {
      if (store != null) {
        final mobile = fields['mobile'].toString();
        final email = fields['email'].toString();
        if (!store.hasUploadSession(mobile, email)) {
          store.clearUploadSession();
          store.progress.value = 'جارٍ تجهيز رفع الصور…';
          final data = await _post(
            '${Urls.partnerApplications}/catalog-upload',
            FormData.fromMap({
              'mobile': mobile,
              'email': email,
              'email_verification_token': fields['email_verification_token'],
            }),
          );
          store._uploadToken = data['upload_token'] as String;
          store._uploadIdentity = '$mobile|${email.trim().toLowerCase()}';
          store._uploadExpires = DateTime.now().add(
            Duration(seconds: (data['expires_in'] as num).toInt() - 10),
          );
        }
        final images = <String, SignupImage>{
          'logo': store.logo!,
          for (var i = 0; i < store.products.length; i++)
            'p$i': store.products[i].image,
        };
        final pending = images.entries
            .where((e) => !identical(store._uploaded[e.key], e.value))
            .toList();
        var completed = images.length - pending.length;
        for (var offset = 0; offset < pending.length; offset += 5) {
          final batch = pending.skip(offset).take(5).toList();
          store.progress.value =
              'جارٍ رفع الصور: $completed من ${images.length}';
          final upload = FormData.fromMap({
            'catalog_upload_token': store._uploadToken,
          });
          for (final entry in batch) {
            upload.files.add(
              MapEntry('images[${entry.key}]', entry.value.upload(entry.key)),
            );
          }
          await _post(
            '${Urls.partnerApplications}/catalog-images',
            upload,
            store: store,
          );
          for (final entry in batch) {
            store._uploaded[entry.key] = entry.value;
          }
          completed += batch.length;
        }
        store.progress.value = 'اكتمل رفع الصور. جارٍ إرسال الطلب…';
      }
      final values = Map<String, dynamic>.from(fields);
      if (store != null) {
        values.remove('email_verification_token');
        values['catalog_upload_token'] = store._uploadToken;
        values['storefront'] = store.catalogJson;
      }
      final body = FormData.fromMap({
        ...values,
        'photo': MultipartFile.fromBytes(
          bytes,
          filename: photo.name.isEmpty ? 'partner.jpg' : photo.name,
        ),
      });
      await _post(Urls.partnerApplications, body, store: store);
    } on DioException {
      throw const StoreSignupFailure(
        'تعذر الاتصال. بياناتك ما زالت موجودة؛ حاول الإرسال مرة أخرى لاستكمال رفع الصور.',
      );
    } finally {
      store?.progress.value = null;
    }
  }

  Future<Map<dynamic, dynamic>> _post(
    String url,
    FormData body, {
    StoreSignupDraft? store,
  }) async {
    final result = await _client.post<dynamic>(
      url,
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
        if (errors is Map) {
          if (errors.containsKey('catalog_upload_token'))
            store?.clearUploadSession();
          if (errors.isNotEmpty &&
              errors.values.first is List &&
              (errors.values.first as List).isNotEmpty) {
            message = (errors.values.first as List).first.toString();
          }
        }
        message ??= data['message']?.toString();
      }
      throw StoreSignupFailure(
        message ?? 'تعذر إرسال الطلب. راجع البيانات وحاول مرة أخرى.',
      );
    }
    return data['data'] is Map ? data['data'] as Map : <dynamic, dynamic>{};
  }

  void close() => _client.close();
}
