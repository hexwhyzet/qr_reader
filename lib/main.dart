import 'dart:async';
import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_verification_code/flutter_verification_code.dart';
import 'package:qr_reader/botton.dart';
import 'package:qr_reader/request.dart';
import 'package:qr_reader/settings.dart';
import 'package:qr_reader/visits.dart';

import 'alert.dart';

const primaryColor = Color(0xFF006940);

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: primaryColor,
      systemNavigationBarColor: primaryColor,
      systemNavigationBarDividerColor: primaryColor,
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  FlexSchemeColor customScheme = FlexSchemeColor.from(primary: primaryColor);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: FlexThemeData.light(colors: customScheme),
      darkTheme: FlexThemeData.dark(colors: customScheme),
      debugShowCheckedModeBanner: false,
      home: Container(
        color: Theme.of(context).primaryColor,
        child: SafeArea(
          top: true,
          left: false,
          right: false,
          bottom: true,
          child: Container(
            color: Theme.of(context).primaryColor,
            child: SafeArea(
              child: NumberStoragePage(),
            ),
          ),
        ),
      ),
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
  String? _name;
  VisitStorage visitStorage = VisitStorage();
  bool _onRounds = false;

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

  Future<bool> _checkAuth(String code) async {
    if (await _submitCode(code)) {
      return true;
    }
    _clearCode();
    return false;
  }

  Future<void> _checkStatus(String code) async {
    Map<String, dynamic>? response = await sendRequest(context, 'GET', 'guard/$code/round_status');
    if (response != null && response['success']) {
      setState(() {
        if (_onRounds = response['is_active']) {
          for (var i = 0; i < response['visits'].length; i++) {
            visitStorage.addVisit(Visit(response['visits'][i]['point']['name'], response['visits'][i]['created_at']));
          }
        }
      });
    }
  }

  Future<bool> _submitCode(String code) async {
    Map<String, dynamic>? response = await sendRequest(context, 'GET', 'auth/$code');
    if (response != null) {
      if (response['success']) {
        await _saveCode(code);
        _saveName(response['name']);
        _numberController.clear();
        _checkStatus(code);
        return true;
      } else {
        raiseErrorFlushbar(context, "Неверный код");
        _numberController.clear();
      }
    }
    return false;
  }

  Future<void> _saveCode(String code) async {
    config.code.setSetting(code);
    setState(() {
      _savedCode = code;
    });
  }

  Future<void> _clearCode() async {
    config.code.clearSetting();
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

  Future<void> _startRound() async {
    Map<String, dynamic>? response = await sendRequest(context, 'POST', 'guard/$_savedCode/start_round');
    if (response != null && response['success']) {
      setState(() {
        _onRounds = true;
      });
    }
  }

  Future<void> _endRound() async {
    Map<String, dynamic>? response = await sendRequest(context, 'POST', 'guard/$_savedCode/end_round');
    if (response != null && response['success']) {
      setState(() {
        _onRounds = false;
        visitStorage.clear();
      });
    }
  }

  void _sendVisit(String number) async {
    Map<String, dynamic>? response = await sendRequest(context, 'POST', 'guard/$_savedCode/visit_point/$number');
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
        toolbarHeight: 65,
        backgroundColor: Theme.of(context).primaryColor,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: SvgPicture.asset(
          'assets/sostra.svg',
          height: 40.0,
          color: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Padding(
              padding: EdgeInsets.only(right: 7.0),
              child: Icon(
                Icons.settings,
                color: Colors.white,
                size: 30.0,
              ),
            ),
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(
                        logoutCallback: _logOut,
                        isAuthed: _savedCode != null,
                      ),
                    ),
                  )
                  .then((_) => setState(() {}));
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
                                if (_onRounds)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 15),
                                    child: StyledWideButton(
                                      text: "ЗАКОНЧИТЬ ОБХОД",
                                      height: 60.0,
                                      bg: Colors.red,
                                      fg: Colors.white,
                                      onPressed: _endRound,
                                    ),
                                  ),
                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Text(_name!,
                                        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
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
                                                  Colors.white,
                                                  Colors.white.withOpacity(0)
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
                          if (_onRounds)
                            StyledWideButton(
                              text: "СКАНИРОВАТЬ",
                              height: 100.0,
                              bg: Theme.of(context).primaryColor,
                              fg: Colors.white,
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => Scaffold(
                                      backgroundColor: Colors.white,
                                      appBar: AppBar(
                                        toolbarHeight: 65,
                                      ),
                                      body: Container(
                                        color: Colors.red,
                                        child: SafeArea(
                                          child: AiBarcodeScanner(
                                            canPop: false,
                                            onScan: (String value) async {
                                              await Future.delayed(Duration(milliseconds: 500));
                                              _sendVisit(value);
                                              Navigator.pop(context);
                                            },
                                            onDetect: (p0) {},
                                            bottomBarText: "Отсканируйте QR код",
                                            controller: MobileScannerController(
                                              detectionSpeed: DetectionSpeed.noDuplicates,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          else
                            StyledWideButton(
                              text: "НАЧАТЬ ОБХОД",
                              height: 100.0,
                              bg: Theme.of(context).dialogBackgroundColor,
                              fg: Theme.of(context).primaryColor,
                              onPressed: _startRound,
                            )
                        ],
                      )),
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
                            textStyle: TextStyle(fontSize: 20.0, color: Theme.of(context).primaryColor),
                            keyboardType: TextInputType.number,
                            length: 6,
                            autofocus: true,
                            digitsOnly: true,
                            underlineWidth: 2.0,
                            onCompleted: (String value) {
                              FocusScope.of(context).unfocus();
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
