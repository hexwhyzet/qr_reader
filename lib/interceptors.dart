import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:qr_reader/request.dart';

class AuthInterceptor extends Interceptor {
  final Future<String?> Function() getAccessToken;
  final Future<String?> Function() getRefreshToken;
  final Future<void> Function(String accessToken) saveAccessToken;
  final Future<void> Function(String accessToken) saveRefreshToken;
  final VoidCallback onUnauthorized;

  AuthInterceptor({
    required this.getAccessToken,
    required this.getRefreshToken,
    required this.saveAccessToken,
    required this.saveRefreshToken,
    required this.onUnauthorized,
  });

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await getAccessToken();
    if (token != null) {
      options.headers["Authorization"] = "Bearer $token";
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        err.requestOptions.extra["disableInterceptor"] != true) {
      final refreshToken = await getRefreshToken();
      if (refreshToken != null) {
        try {
          final newAccessToken = await _refreshToken(refreshToken);
          if (newAccessToken != null) {
            saveAccessToken(newAccessToken);
            final options = err.requestOptions;
            options.extra["disableInterceptor"] = true; // Чтобы не поймать
            // рекурсивно проваленный запрос
            options.headers["Authorization"] = "Bearer $newAccessToken";
            final response = await Dio().fetch(options);
            return handler.resolve(response);
          }
        } catch (_) {
          onUnauthorized(); // Если не удалось обновить токен
        }
      } else {
        onUnauthorized(); // Если нет refresh_token
      }
    }
    super.onError(err, handler);
  }

  Future<String?> _refreshToken(String refreshToken) async {
    try {
      final response = await sendRequest('POST', 'token/refresh/',
          body: {'refresh': refreshToken}, disableInterceptor: true);
      if (response != null && response.containsKey('access')) {
        return response['access'];
      }
    } catch (e) {
      print('Error refreshing token: $e');
    }
    return null;
  }
}
