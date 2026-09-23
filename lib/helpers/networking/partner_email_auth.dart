import 'package:dio/dio.dart';
import 'urls.dart';

class PartnerAuthFailure implements Exception {
  const PartnerAuthFailure(this.message, {this.retryAfter = 0});
  final String message;
  final int retryAfter;
}

class PartnerEmailChallenge {
  const PartnerEmailChallenge(this.id, this.resendAfter);
  final String id;
  final int resendAfter;
}

/// Public auth requests use no session token and never log OTPs or passwords.
class PartnerEmailAuth {
  PartnerEmailAuth({Dio? client})
    : _client =
          client ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 35),
            ),
          );
  final Dio _client;

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client.post<dynamic>(
        '${Urls.baseUrl}$path',
        data: body,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'X-App-Scope': 'go_partner',
            'Lang': 'ar',
          },
        ),
      );
      if (response.data is! Map || response.data['status'] != 'Success') {
        throw const PartnerAuthFailure('تعذر إكمال الطلب. حاول مرة أخرى.');
      }
      final data = response.data['data'];
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } on DioException catch (error) {
      final data = error.response?.data;
      String? message;
      if (data is Map) {
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty && errors.values.first is List) {
          message = (errors.values.first as List).firstOrNull?.toString();
        }
        message ??= data['message']?.toString();
      }
      throw PartnerAuthFailure(
        message ?? 'تعذر الاتصال بالخادم. تحقق من الإنترنت وحاول مرة أخرى.',
        retryAfter:
            int.tryParse(error.response?.headers.value('retry-after') ?? '') ??
            0,
      );
    }
  }

  Future<PartnerEmailChallenge> requestCode({
    required String purpose,
    required String mobile,
    String? email,
  }) async {
    final data = await _post('partner-auth/email/request', {
      'purpose': purpose,
      'mobile': mobile,
      if (email != null) 'email': email.trim().toLowerCase(),
    });
    final id = data['challenge_id']?.toString();
    if (id == null || id.isEmpty)
      throw const PartnerAuthFailure('تعذر إرسال الكود. حاول مرة أخرى.');
    return PartnerEmailChallenge(
      id,
      (data['resend_after'] as num?)?.toInt() ?? 60,
    );
  }

  Future<String> verify(String challengeId, String code) async {
    final data = await _post('partner-auth/email/verify', {
      'challenge_id': challengeId,
      'code': code,
    });
    final proof = data['email_verification_token']?.toString();
    if (proof == null || proof.length != 64)
      throw const PartnerAuthFailure('تعذر تأكيد البريد. اطلب كودًا جديدًا.');
    return proof;
  }

  Future<void> setPassword({
    required bool activation,
    required String mobile,
    required String proof,
    required String password,
    required String confirmation,
  }) async {
    await _post(
      activation
          ? 'partner-applications/activate'
          : 'partner-auth/password/reset',
      {
        'mobile': mobile,
        'email_verification_token': proof,
        'password': password,
        'password_confirmation': confirmation,
      },
    );
  }
}
