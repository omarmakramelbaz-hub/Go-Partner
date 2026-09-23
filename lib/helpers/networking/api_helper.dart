import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../view/layout/auth/screen/login_screen.dart';
import '../extension/context_extension.dart';
import '../hive/hive_methods.dart';
import '../routes/app_routers_import.dart';
import '../utils/common_methods.dart';

enum ResponseState { sleep, offline, loading, pagination, complete, error, unauthorized }

class ApiResponse {
  ResponseState state;

  dynamic data;
  ApiResponse({required this.state, required this.data});
}

class ApiHelper {
  static ApiHelper? _instance;

  ApiHelper._();

  static ApiHelper get instance {
    _instance ??= ApiHelper._();

    return _instance!;
  }

  // final String _serverKey = '';

  MediaType appMediaType(String path) {
    List<String> list = '${lookupMimeType(path)}'.split('/');
    return MediaType('${list.firstOrNull}', '${list.lastOrNull}');
  }

  final Dio _dio = Dio()
    ..interceptors.addAll(
      kDebugMode
          ? [
              PrettyDioLogger(
                requestHeader: false,
                requestBody: false,
                responseBody: false,
                responseHeader: false,
                compact: false,
                error: false,
                request: true,
              ),
            ]
          : [],
    );

  Options _options(Map<String, String>? headers, bool hasToken) {
    return Options(
      contentType: 'application/json',
      followRedirects: false,
      validateStatus: (status) {
        return true;
      },
      headers: {
        'Accept': 'application/json',
        'X-App-Scope': 'go_partner',
        //  'Accept-Language': HiveMethods.getLang(),
        'Lang': HiveMethods.getLang(),
        if (HiveMethods.getToken() != null && hasToken) ...{'Authorization': 'Bearer ${HiveMethods.getToken()}'},
        ...?headers,
      },
    );
  }

  Map<String, String> _offlineMessage() {
    return {
      'message': AppRouters.navigatorKey.currentContext!.apiTr(
        ar: 'تأكد من الاتصال بالإنترنت',
        en: 'Make sure you are connected to the internet',
      ),
    };
  }

  Map<String, String> _errorMessage() {
    return {'message': AppRouters.navigatorKey.currentContext!.apiTr(ar: 'حدث خطأ', en: 'An error occurred')};
  }

  Future<ApiResponse> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    void Function()? onFinish,
    void Function(int, int)? onReceiveProgress,
    bool hasToken = true,
  }) async {
    ApiResponse responseJson;
    if (await CommonMethods.hasConnection() == false) {
      responseJson = ApiResponse(state: ResponseState.offline, data: _offlineMessage());
      Future.delayed(Duration.zero, onFinish);
      return responseJson;
    }

    try {
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: _options(headers, hasToken),
        onReceiveProgress: onReceiveProgress,
      );
      responseJson = _buildResponse(response);
      Future.delayed(Duration.zero, onFinish);
    } on DioException {
      responseJson = ApiResponse(state: ResponseState.error, data: _errorMessage());
      Future.delayed(Duration.zero, onFinish);
    } on SocketException {
      responseJson = ApiResponse(state: ResponseState.offline, data: _offlineMessage());
      Future.delayed(Duration.zero, onFinish);
      return responseJson;
    }
    return responseJson;
  }

  Future<ApiResponse> post(
    String url, {
    Map<String, dynamic>? queryParameters,
    dynamic body,
    Map<String, String>? headers,
    void Function()? onFinish,
    void Function(int, int)? onReceiveProgress,
    void Function(int, int)? onSendProgress,
    bool hasToken = true,
  }) async {
    ApiResponse responseJson;

    if (await CommonMethods.hasConnection() == false) {
      responseJson = ApiResponse(state: ResponseState.offline, data: _offlineMessage());
      Future.delayed(Duration.zero, onFinish);
      return responseJson;
    }
    try {
      final response = await _dio.post(
        url,
        queryParameters: queryParameters,
        data: body,
        options: _options(headers, hasToken),
        onReceiveProgress: onReceiveProgress,
        onSendProgress: onSendProgress,
      );
      responseJson = _buildResponse(response);
      Future.delayed(Duration.zero, onFinish);
    } on DioException {
      responseJson = ApiResponse(state: ResponseState.error, data: _errorMessage());
      Future.delayed(Duration.zero, onFinish);
      return responseJson;
    } on SocketException {
      responseJson = ApiResponse(state: ResponseState.offline, data: _offlineMessage());
      Future.delayed(Duration.zero, onFinish);
      return responseJson;
    }
    return responseJson;
  }

  Future<ApiResponse> put(
    String url, {
    Map<String, dynamic>? queryParameters,
    dynamic body,
    Map<String, String>? headers,
    void Function()? onFinish,
    void Function(int, int)? onReceiveProgress,
    void Function(int, int)? onSendProgress,
    bool hasToken = true,
  }) async {
    ApiResponse responseJson;

    if (await CommonMethods.hasConnection() == false) {
      responseJson = ApiResponse(state: ResponseState.offline, data: _offlineMessage());
      Future.delayed(Duration.zero, onFinish);
      return responseJson;
    }
    try {
      final response = await _dio.put(
        url,
        queryParameters: queryParameters,
        data: body,
        options: _options(headers, hasToken),
        onReceiveProgress: onReceiveProgress,
        onSendProgress: onSendProgress,
      );
      responseJson = _buildResponse(response);
      Future.delayed(Duration.zero, onFinish);
    } on DioException {
      responseJson = ApiResponse(state: ResponseState.error, data: _errorMessage());
      Future.delayed(Duration.zero, onFinish);
    } on SocketException {
      responseJson = ApiResponse(state: ResponseState.offline, data: _offlineMessage());
      Future.delayed(Duration.zero, onFinish);
      return responseJson;
    }
    return responseJson;
  }

  Future<ApiResponse> patch(
    String url, {
    Map<String, dynamic>? queryParameters,
    dynamic body,
    Map<String, String>? headers,
    void Function()? onFinish,
    void Function(int, int)? onReceiveProgress,
    void Function(int, int)? onSendProgress,
    bool hasToken = true,
  }) async {
    ApiResponse responseJson;

    if (await CommonMethods.hasConnection() == false) {
      responseJson = ApiResponse(state: ResponseState.offline, data: _offlineMessage());
      Future.delayed(Duration.zero, onFinish);
      return responseJson;
    }
    try {
      final response = await _dio.patch(
        url,
        queryParameters: queryParameters,
        data: body,
        options: _options(headers, hasToken),
        onReceiveProgress: onReceiveProgress,
        onSendProgress: onSendProgress,
      );
      responseJson = _buildResponse(response);
      Future.delayed(Duration.zero, onFinish);
    } on DioException {
      responseJson = ApiResponse(state: ResponseState.error, data: _errorMessage());
      Future.delayed(Duration.zero, onFinish);
    } on SocketException {
      responseJson = ApiResponse(state: ResponseState.offline, data: _offlineMessage());
      Future.delayed(Duration.zero, onFinish);
      return responseJson;
    }
    return responseJson;
  }

  Future<ApiResponse> delete(
    String url, {
    Map<String, dynamic>? queryParameters,
    dynamic body,
    Map<String, String>? headers,
    void Function()? onFinish,
    bool hasToken = true,
  }) async {
    ApiResponse responseJson;

    if (await CommonMethods.hasConnection() == false) {
      responseJson = ApiResponse(state: ResponseState.offline, data: _offlineMessage());
      Future.delayed(Duration.zero, onFinish);
      return responseJson;
    }
    try {
      final response = await _dio.delete(
        url,
        queryParameters: queryParameters,
        data: body,
        options: _options(headers, hasToken),
      );
      responseJson = _buildResponse(response);
      Future.delayed(Duration.zero, onFinish);
    } on DioException {
      responseJson = ApiResponse(state: ResponseState.error, data: _errorMessage());
      Future.delayed(Duration.zero, onFinish);
    } on SocketException {
      responseJson = ApiResponse(state: ResponseState.offline, data: _offlineMessage());
      Future.delayed(Duration.zero, onFinish);
      return responseJson;
    }
    return responseJson;
  }

  Future<ApiResponse> download(
    String url, {
    Map<String, dynamic>? queryParameters,
    dynamic body,
    Map<String, String>? headers,
    void Function()? onFinish,
    void Function(int, int)? onReceiveProgress,
    void Function(int, int)? onSendProgress,
    bool hasToken = true,
  }) async {
    ApiResponse responseJson;

    if (await CommonMethods.hasConnection() == false) {
      responseJson = ApiResponse(state: ResponseState.offline, data: _offlineMessage());
      Future.delayed(Duration.zero, onFinish);
      return responseJson;
    }
    final fileName = path.basename(url);
    final savePath = await _getFilePath(fileName);
    try {
      final response = await _dio.download(
        url,
        savePath,
        queryParameters: queryParameters,
        data: body,
        options: _options(headers, hasToken),
        onReceiveProgress: onReceiveProgress,
      );
      responseJson = _buildResponse(response);
      Future.delayed(Duration.zero, onFinish);
    } on DioException {
      responseJson = ApiResponse(state: ResponseState.error, data: _errorMessage());
      Future.delayed(Duration.zero, onFinish);
    } on SocketException {
      responseJson = ApiResponse(state: ResponseState.offline, data: _offlineMessage());
      Future.delayed(Duration.zero, onFinish);
      return responseJson;
    }
    return responseJson;
  }

  ApiResponse _buildResponse(Response<dynamic> response) {
    switch (response.statusCode) {
      case 200:
        var responseJson = response.data;
        return ApiResponse(state: ResponseState.complete, data: responseJson);
      case 201:
        var responseJson = response.data;
        return ApiResponse(state: ResponseState.complete, data: responseJson);
      case 400:
        var responseJson = response.data;
        return ApiResponse(state: ResponseState.error, data: responseJson);
      case 401:
        var responseJson = response.data;
        Future.delayed(Duration.zero, () {
          AppRouters.navigatorKey.currentState?.pushNamedAndRemoveUntil(LoginScreen.routeName, (route) => false);
        });
        return ApiResponse(state: ResponseState.unauthorized, data: responseJson);
      case 422:
        var responseJson = response.data;
        return ApiResponse(state: ResponseState.error, data: responseJson);
      case 403:
        var responseJson = response.data;
        return ApiResponse(state: ResponseState.error, data: responseJson);
      case 500:
      default:
        var responseJson = response.data;
        return ApiResponse(state: ResponseState.error, data: responseJson);
    }
  }

  Future<String> _getFilePath(uniqueFileName) async {
    String path = '';
    Directory dir = await path_provider.getApplicationDocumentsDirectory();
    path = '${dir.path}/$uniqueFileName.pdf';
    return path;
  }

  Future<String> getAccessToken() async {
    final serviceAccountJson = {
      'type': 'service_account',
      'project_id': 'faskhaninja',
      'private_key_id': 'a2e8298ee5a0812852d3ff6d0d4dbd763bc92383',
      'private_key':
          '-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCY2rqvJC9m65xM\nzxpVSbO1ENM6Y+yeHs+PG5NIeY0m7uw1OJXE/VS8b3mIFc0stZCMfyhc6UbwoGac\n05JXrVG62WtwaF+sJIVicnAeavLSLLvoTqQeB01vqa8yi8m7JU2fpYbPLT2+7ipP\nvDl0PQzbvvmiWfNqm0QrxG4fY40ELGLsHxDb02ha9ZXZ5+Izr5Z9Iv1eQ85D5vMF\n4gVyDDuHYhUwdHnLQxHSM+wobLJo2fhvA0ozJAthFGZFDjHnsIzEOp4eVSrdFI5a\nQRnqxgMcE9NEPMB11NMorjM6fUaFkXDBZm7Au1/R3vE8k2nIlWUdW05QskaEKAqF\nxypsmKmnAgMBAAECggEABAIl7yBPpK8kbzrnH0Pn+5trWHkcMuxk18oyGhrA/QCJ\nvJc/IUi2fYix6TAjBM8hLFpWORhKgy8Mt/pDwn12I195xy8pNFn8hNqye9dCcuFy\n+PX4NuH+JCukq79uY6CZatJ/pSMz93i8pNpWm62WLEZJpyFYIAYtGclW6pEJ5/Wb\n9EIsghKq0Wo2tzI/jzCmCpcgvIXv2ACmYqQ7ROzSfuk5XBBrLlFImYSX5cq1j1+2\npdpUe/kqkeDuT3jjaLUJ44NV3TAB1C49BcvVgAaOH2hx1dKFFUXu9DWFN/Bl6OFV\n9aUFycVE2Bl1adYGoWuLMX0Shx15qdTNbjjzYyMJoQKBgQDHW8+F2xt5QY/E18Cz\n0J+bFxkRt8xTy2Mea7QGqlRj2WKgPbANSijHbU3cEAqzfi7ywOn38LWQtBx6tiKQ\nHMqTZz/38Q8W+9nGy78Rsi3oqdccYrkuJOYWRaRgN+LslxzP3CK2zVfv9Iw78dKt\nrIbrhPE/fjMd16HHIBByON6PTwKBgQDESHitrzxZpgr6nvbl8KHkIxvfa0PK/EHL\n0PMotJeX9zwfTQXBsJXPscoCLGPhOjpK89NaWYPBpxuBEvhPoOT912ZhcPE/90+j\nOpkB8KDP+SF2/u6Aoe2sOnCfBkIH4iWxkfosIjuP+RNe7uU9cOnJNsAhOBuhl8jO\n3/B1XVNqKQKBgDux2ioSud9NKmee0y0Ew0YFXJRZnO1acYuiZH26cxqS9V1WG2lf\nU2aj7DSA+TNWDWjTKzv67+Msi3qTHzZX6LDKsfTkUchoEYXdbJE38VdBxA/T3+9Z\nTSxOHjJRibmeZho3qI1kX3iSmYs5lgQ7LQtI+5Qvjc7Zyq99gm8xaDMxAoGABjPg\nFGUAPDkCCc9yL+v9wa7WV6YVG1oDXkR5GqUyUSwP61FMyEUjRs/weUcb1Oc5Jls0\nJ5vCjSERvm9yB1onQlpHMvcVuJbBHoBgi24mNsxBoXgG42u6jgG+w1e4SHV+CXF6\nfWCLj04orYxRFDL4QFKJmcMjJGUehGMRPzQ2yZkCgYBg1Z6IHIgg7fGpUypn7DQ4\n6eUxdYU3q56PnOL1G1LE97GaicmdCSu5giBEAopwjEOvfhigUbpyT2Bi/xb6CPsU\nSWnkhlTuB954YIZiX3cOcxLbjonEgC1QndO6CC9DTUDC/3UAgxuLGRM/IwZiS9cU\nL/fK+kVIwlSW4MCbdoov+g==\n-----END PRIVATE KEY-----\n',
      'client_email': 'faskhaninjavendor@faskhaninja.iam.gserviceaccount.com',
      'client_id': '110742361795732645595',
      'auth_uri': 'https://accounts.google.com/o/oauth2/auth',
      'token_uri': 'https://oauth2.googleapis.com/token',
      'auth_provider_x509_cert_url': 'https://www.googleapis.com/oauth2/v1/certs',
      'client_x509_cert_url':
          'https://www.googleapis.com/robot/v1/metadata/x509/faskhaninjavendor%40faskhaninja.iam.gserviceaccount.com',
      'universe_domain': 'googleapis.com',
    };
    List<String> scopes = [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/firebase.database',
      'https://www.googleapis.com/auth/firebase.messaging',
    ];

    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );
    //get the access toke
    auth.AccessCredentials credentials = await auth.obtainAccessCredentialsViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
      client,
    );
    client.close();
    return credentials.accessToken.data;
  }

  sendNotification({
    required String deviceToken,
    required String titleName,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final String serverAccessTokenKey = await getAccessToken();
    String endpointFirebaseCLoudMessaging = 'https://fcm.googleapis.com/v1/projects/faskhaninja/messages:send';
    // final String currentFCMToken =
    //     FirebaseMessaging.instance.getToken().toString();
    final Map<String, dynamic> message = {
      'message': {
        'token': deviceToken,
        'notification': {'title': titleName, 'body': body},
        'data': data,
      },
    };

    final response = await http.post(
      Uri.parse(endpointFirebaseCLoudMessaging),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $serverAccessTokenKey'},
      body: jsonEncode(message),
    );
    if (response.statusCode == 200) {
      log('notification sent"$deviceToken ${response.body}');
      log(data.toString());
      log(body.toString());
    } else {
      log('notification not sent ${response.statusCode} -----> $deviceToken ${response.body}');
      log(data.toString());
      log(body.toString());
    }
  }

  // Future<void> sendNotification({
  //   required String title,
  //   required String body,
  //   required String to,
  //   Map<String, dynamic>? data,
  //   void Function()? onFinish,
  // }) async {
  //   try {
  //     await http.post(
  //       Uri.parse('https://fcm.googleapis.com/fcm/send'),
  //       headers: <String, String>{
  //         'Content-Type': 'application/json',
  //         'Authorization': 'key=$_serverKey',
  //       },
  //       body: jsonEncode(
  //         <String, dynamic>{
  //           'notification': <String, dynamic>{'body': body, 'title': title},
  //           'priority': 'high',
  //           'data': <String, dynamic>{...?data},
  //           'to': to,
  //         },
  //       ),
  //     );
  //     Future.delayed(Duration.zero, onFinish);
  //   } catch (e) {
  //     Future.delayed(Duration.zero, onFinish);
  //     log("error push notification");
  //   }
  // }
}
