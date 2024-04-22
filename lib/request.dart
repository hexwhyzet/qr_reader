import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:qr_reader/settings.dart';

Future<Map<String, dynamic>?> sendRequest(String method, String endpoint, {Map<String, String>? body}) async {
  String hostname = await config.hostname.getSetting();
  try {
    var url = Uri.parse('http://$hostname/api/$endpoint');
    var response = (method == 'POST') ? await http.post(url, body: body) : await http.get(url);

    if (response.statusCode != 200) {
      print('Server error: ${response.body}');
    }
    return jsonDecode(response.body);
  } catch (e) {
    print('Failed to send request to the server: $e');
  }
}
