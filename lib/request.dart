import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:qr_reader/alert.dart';

import 'package:qr_reader/settings.dart';

Future<Map<String, dynamic>?> sendRequest(context, String method, String endpoint, {Map<String, String>? body}) async {
  String hostname = await config.hostname.getSetting();
  try {
    var url = Uri.parse('http://$hostname/api/$endpoint');
    print(url);
    var response = (method == 'POST') ? await http.post(url, body: body).timeout(Duration(milliseconds: 500)) : await http.get(url).timeout(Duration(milliseconds: 1000));

    if (response.statusCode != 200) {
      print('Server error: ${response.body}');
    }
    return jsonDecode(response.body);
  } catch (e) {
    raiseErrorFlushbar(context, "Ошибка запроса, проверьте интернет соединение");
    print('Failed to send request to the server: $e');
  }
}
