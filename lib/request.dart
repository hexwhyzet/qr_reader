import 'dart:developer' as console;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
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

Future<Response> sendRequestWithStatus(String method, String endpoint,
    {Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    bool disableInterceptor = false,
    bool isMultipart = false}) async {
  String hostname = await config.hostname.getSetting();
  var url = Uri.parse('https://$hostname/api/$endpoint');
  Response response;

  var options = Options(
    extra: {"disableInterceptor": disableInterceptor},
  );

  if (isMultipart) {
    options.headers = {"Content-Type": "multipart/form-data"};
  }

  if (method == 'POST') {
    if (isMultipart) {
      response = await dio
          .post(url.toString(),
              data: FormData.fromMap(body!),
              queryParameters: queryParams,
              options: options)
          .timeout(const Duration(seconds: 5));
    } else {
      response = await dio
          .post(url.toString(),
              data: body, queryParameters: queryParams, options: options)
          .timeout(const Duration(seconds: 5));
    }
  } else if (method == 'GET') {
    response = await dio
        .get(url.toString(),
            data: body, queryParameters: queryParams, options: options)
        .timeout(const Duration(seconds: 5));
  } else if (method == 'DELETE') {
    response = await dio
        .delete(url.toString(),
            data: body, queryParameters: queryParams, options: options)
        .timeout(const Duration(seconds: 5));
  } else {
    throw Error();
  }

  if (response.statusCode != 200) {
    print('Server error: ${response.data}');
  }
  return response;
}

Future<dynamic> sendFileWithMultipart(
    String method, String endpoint, XFile file, String fileKey,
    {Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    bool disableInterceptor = false}) async {
  body ??= {};
  Uint8List content = await file.readAsBytes();
  body[fileKey] = MultipartFile.fromBytes(content,
      filename: file.name);
  return sendRequestWithStatus(method, endpoint,
      body: body,
      queryParams: queryParams,
      disableInterceptor: disableInterceptor,
      isMultipart: true);
}

Future<dynamic> sendRequest(String method, String endpoint,
    {Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    bool disableInterceptor = false}) async {
  return (await sendRequestWithStatus(method, endpoint,
          body: body,
          queryParams: queryParams,
          disableInterceptor: disableInterceptor))
      .data;
}
