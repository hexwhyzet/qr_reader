import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:qr_reader/settings.dart';

import 'interceptors.dart';

final dio = Dio();

Future<void> setupDioInterceptors({
  required Future<String?> Function() getToken,
  required Future<String?> Function() getRefreshToken,
  required Future<void> Function(String) saveToken,
  required Future<void> Function(String) saveRefreshToken,
  required VoidCallback onUnauthorized,
}) async {
  dio.interceptors.add(AuthInterceptor(
    getAccessToken: getToken,
    getRefreshToken: getRefreshToken,
    saveAccessToken: saveToken,
    saveRefreshToken: saveRefreshToken,
    onUnauthorized: onUnauthorized,
  ));
}

Future<dynamic> sendRequest(String method, String endpoint,
    {Map<String, dynamic>? body, Map<String, dynamic>? queryParams}) async {
  String hostname = await config.hostname.getSetting();
  var url = Uri.parse('http://$hostname/api/$endpoint');
  Response response;

  if (method == 'POST') {
    response = await dio.post(url.toString(), data: body, queryParameters: queryParams).timeout(const Duration(seconds: 5));
  } else if (method == 'GET') {
    response = await dio.get(url.toString(), data: body, queryParameters: queryParams).timeout(const Duration(seconds: 5));
  } else if (method == 'DELETE') {
    response = await dio.delete(url.toString(), data: body, queryParameters: queryParams).timeout(const Duration(seconds: 5));
  } else {
    throw Error();
  }

  if (response.statusCode != 200) {
    print('Server error: ${response.data}');
  }
  return response.data;
}
