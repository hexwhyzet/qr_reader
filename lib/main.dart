import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_verification_code/flutter_verification_code.dart';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';
import 'package:qr_reader/request.dart';
import 'package:qr_reader/settings.dart';
import 'package:qr_reader/visits.dart';
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
  VisitStorage visitStorage = VisitStorage();

  @override
  void initState() {
    super.initState();
    _loadAndCheckNumber();
  }

  Future<void> _loadAndCheckNumber() async {
    String? code = await config.code.getSetting();
    if (code != null) {
      await _checkAuth(code);
    } else {
      _logOut();
    }
  }

  void _handleServerResponse(String responseBody) {
    var data = json.decode(responseBody);
    setState(() {
      _serverResponse = data['message'];
    });
  }

  Future<bool> _checkAuth(String code) async {
    if (await _submitCode(code)) {
      return true;
    }
    _clearCode();
    return false;
  }

  Future<void> _checkStatus(String code) async {
    Map<String, dynamic>? response = await sendRequest('GET', 'status/$code');
    print(response);
    if (response != null && response['success']) {
      print("JOPA");
      setState(() {
        for (var i = 0; i < response['points'].length; i++) {
          print("KUKU");
          print(response['points'][i]['timestamp']);
          visitStorage.addVisit(Visit(response['points'][i]['name'], response['points'][i]['timestamp']));
        }
      });
    }
  }

  Future<bool> _submitCode(String code) async {
    Map<String, dynamic>? response = await sendRequest('GET', 'auth/$code');
    if (response != null && response['success']) {
      await _saveCode(code);
      _saveName(response['name']);
      _numberController.clear();
      _checkStatus(code);
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
    visitStorage.clear();
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

  void _sendVisit(String number) async {
    Map<String, dynamic>? response = await sendRequest('POST', 'visited/$number');
    if (response == null || !response['success']) {
      print("Error occured");
      print(response);
    } else {
      setState(() {
        visitStorage.addVisit(Visit(response['name'], DateTime.now().millisecondsSinceEpoch));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: Text('QR сканер'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => SettingsScreen(logoutCallback: _logOut, isAuthed: _savedCode != null)),
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
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (_savedCode != null && _name != null)
                      Expanded(
                          child: Column(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Text(_name!,
                                        style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center),
                                  ),
                                ),
                                Expanded(
                                    child: Container(
                                  child: Stack(
                                    children: [
                                      Align(
                                        alignment: Alignment.bottomCenter,
                                        child: VisitListWidget(storage: visitStorage),
                                      ),
                                      Align(
                                        alignment: Alignment.topCenter,
                                        child: IgnorePointer(
                                          child: Container(
                                            height: 100,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Theme.of(context).backgroundColor,
                                                  Theme.of(context).backgroundColor.withOpacity(0)
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                          Container(height: 10),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.9,
                            height: 100.0,
                            child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                              double fontSize = (constraints.maxWidth * 0.8) / 'СКАНИРОВАТЬ'.length;
                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                // onPressed: () async {
                                onPressed: () async {
                                  _sendVisit("122");
                                  // await Navigator.of(context).push(
                                  //   MaterialPageRoute(
                                  //     builder: (context) => Scaffold(
                                  //       appBar: AppBar(),
                                  //       body: Container(
                                  //         color: Colors.white,
                                  //         child: SafeArea(
                                  //           child: AiBarcodeScanner(
                                  //             canPop: false,
                                  //             onScan: (String value) async {
                                  //               await Future.delayed(Duration(milliseconds: 250));
                                  //               // _sendNumber(value);
                                  //               Navigator.pop(context);
                                  //             },
                                  //             onDetect: (p0) {},
                                  //             bottomBarText: "Отсканируйте QR код",
                                  //             controller: MobileScannerController(
                                  //               detectionSpeed: DetectionSpeed.noDuplicates,
                                  //             ),
                                  //           ),
                                  //         ),
                                  //       ),
                                  //     ),
                                  //   ),
                                  // );
                                },
                                child: Text("СКАНИРОВАТЬ",
                                    style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
                              );
                            }),
                          ),
                        ],
                      )),
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
                          // Pinput(
                          //   length: 6,
                          //   defaultPinTheme: defaultPinTheme,
                          //   focusedPinTheme: focusedPinTheme,
                          //   submittedPinTheme: submittedPinTheme,
                          //   validator: (s) {
                          //     return s == '2222' ? null : 'Pin is incorrect';
                          //   },
                          //   pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                          //   showCursor: true,
                          //   onCompleted: (pin) => print(pin),
                          // )
                          VerificationCode(
                            textStyle: TextStyle(fontSize: 20.0, color: Theme.of(context).primaryColor),
                            keyboardType: TextInputType.number,
                            length: 6,
                            autofocus: true,
                            digitsOnly: true,
                            underlineWidth: 2.0,
                            onCompleted: (String value) {
                              _submitCode(value);
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
