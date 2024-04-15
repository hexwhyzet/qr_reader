import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_verification_code/flutter_verification_code.dart';
import 'package:http/http.dart' as http;
import 'package:qr_reader/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: NumberStoragePage(),
    );
  }
}

class NumberStoragePage extends StatefulWidget {
  @override
  _NumberStoragePageState createState() => _NumberStoragePageState();
}

class _NumberStoragePageState extends State<NumberStoragePage> {
  TextEditingController _numberController = TextEditingController();
  String? _savedCode;
  bool _isLoading = false;
  String? _serverResponse;
  String? _name;

  @override
  void initState() {
    super.initState();
    _loadAndCheckNumber();
  }

  Future<void> _loadAndCheckNumber() async {
    final prefs = await SharedPreferences.getInstance();
    String? code = prefs.getString('saved_code');
    if (code != null) {
      await _checkAuth(code);
    } else {
      _logOut();
    }
  }

  Future<Map<String, dynamic>?> _sendRequest(String method, String endpoint,
      {Map<String, String>? body}) async {
    setState(() {
      _isLoading = true;
    });
    String hostname = await config.hostname.getSetting();
    try {
      var url = Uri.parse('http://$hostname/api/$endpoint');
      var response = (method == 'POST')
          ? await http.post(url, body: body)
          : await http.get(url);

      if (response.statusCode == 200) {
        _handleServerResponse(response.body);
      } else {
        print('Server error: ${response.body}');
      }
      return jsonDecode(response.body);
    } catch (e) {
      print('Failed to send request to the server: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleServerResponse(String responseBody) {
    var data = json.decode(responseBody);
    setState(() {
      _serverResponse = data['message'];
    });
  }

  Future<bool> _checkAuth(String code) async {
    if (await _submitNumber(code)) {
      return true;
    }
    _clearCode();
    return false;
  }

  Future<bool> _submitNumber(String code) async {
    Map<String, dynamic>? response = await _sendRequest('GET', 'auth/$code');
    if (response != null && response['success']) {
      await _saveCode(code);
      _saveName(response['name']);
      _numberController.clear();
      return true;
    }
    return false;
  }

  Future<void> _saveCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_number', code);
    setState(() {
      _savedCode = code;
    });
  }

  Future<void> _clearCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_number');
    setState(() {
      _savedCode = null;
    });
  }

  Future<void> _saveName(String name) async {
    setState(() {
      _name = name;
    });
  }

  Future<void> _clearName() async {
    setState(() {
      _name = null;
    });
  }

  Future<void> _logOut() async {
    await _clearCode();
    await _clearName();
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text('Please enter a six-digit number.'),
          actions: <Widget>[
            TextButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _sendNumber(String number) async {
    Map<String, dynamic>? response = await _sendRequest('POST', 'visited/$number');
    if (response == null || !response['success']) {
      print("Error occured");
      print(response);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR сканер'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                        logoutCallback: _logOut, isAuthed: _savedCode != null)),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: _isLoading
              ? CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (_savedCode != null && _name != null)
                      Column(
                        children: [
                          Padding(
                            child: Text(_name!,
                                style: TextStyle(
                                    fontSize: 28.0,
                                    fontWeight: FontWeight.bold)),
                            padding: EdgeInsets.only(bottom: 10),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => Container(
                                    color: Colors.white,
                                    child: SafeArea(
                                      child: AiBarcodeScanner(
                                        canPop: false,
                                        onScan: (String value) async {
                                          await Future.delayed(Duration(milliseconds: 250));
                                          _sendNumber(value);
                                          Navigator.pop(context);
                                        },
                                        onDetect: (p0) {},
                                        bottomBarText: "Отсканируйте QR код",
                                        controller: MobileScannerController(
                                          detectionSpeed:
                                          DetectionSpeed.noDuplicates,
                                        ),
                                      ),
                                    ),
                                  )
                                ),
                              );
                            },
                            child: Text('Сканировать QR код'),
                          ),
                        ],
                      ),
                    if (_serverResponse != null)
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Server Response: $_serverResponse'),
                      ),
                    if (_savedCode == null)
                      Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(bottom: 15),
                            child: Text(
                              "Введите авторизационный код",
                              style: TextStyle(fontSize: 20.0),
                            ),
                          ),
                          VerificationCode(
                            textStyle: TextStyle(
                                fontSize: 20.0,
                                color: Theme.of(context).primaryColor),
                            keyboardType: TextInputType.number,
                            length: 6,
                            autofocus: true,
                            digitsOnly: true,
                            underlineWidth: 2.0,
                            onCompleted: (String value) {
                              _submitNumber(value);
                            },
                            onEditing: (bool value) {},
                          ),
                        ],
                      )
                  ],
                ),
        ),
      ),
    );
  }
}
