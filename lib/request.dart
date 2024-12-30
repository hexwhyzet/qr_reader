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

Future<Map<String, dynamic>?> sendRequest(String method, String endpoint,
    {Map<String, String>? body}) async {
  String hostname = await config.hostname.getSetting();
  var url = Uri.parse('http://$hostname/api/$endpoint');
  var response = (method == 'POST')
      ? await dio.post(url.toString(), data: body).timeout(const Duration(seconds: 5))
      : await dio.get(url.toString()).timeout(const Duration(seconds: 5));

  if (response.statusCode != 200) {
    print('Server error: ${response.data}');
  }
  return response.data;
}
