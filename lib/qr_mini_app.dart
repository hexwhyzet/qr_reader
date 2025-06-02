import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:qr_reader/request.dart';
import 'package:qr_reader/settings.dart';
import 'package:qr_reader/visits.dart';

import 'alert.dart';
import 'botton.dart';

class QRMiniApp extends StatefulWidget {
  @override
  _QRMiniAppState createState() => _QRMiniAppState();
}

class _QRMiniAppState extends State<QRMiniApp> {
  TextEditingController _numberController = TextEditingController();
  String? _savedCode;
  bool _isLoading = true;
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
    setState(() {
      _isLoading = false;
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
    Map<String, dynamic>? response =
        await sendRequest('GET', 'guard/$code/round_status');
    if (response != null && response['success']) {
      setState(() {
        if (_onRounds = response['is_active']) {
          for (var i = 0; i < response['visits'].length; i++) {
            visitStorage.addVisit(Visit(
                Point.fromJson(response['visits'][i]['point']),
                response['visits'][i]['created_at']));
          }
        }
      });
    }
  }

  Future<bool> _submitCode(String code) async {
    Map<String, dynamic>? response = await sendRequest('GET', 'auth/$code');
    if (response != null) {
      if (response['success']) {
        await _saveCode(code);
        _name = response['name'];
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
    Map<String, dynamic>? response =
        await sendRequest('POST', 'guard/$_savedCode/start_round');
    if (response != null && response['success']) {
      setState(() {
        _onRounds = true;
      });
    }
  }

  Future<void> _endRound() async {
    Map<String, dynamic>? response =
        await sendRequest('POST', 'guard/$_savedCode/end_round');
    if (response != null && response['success']) {
      setState(() {
        _onRounds = false;
        visitStorage.clear();
      });
    }
  }

  void _sendVisit(String number) async {
    Map<String, dynamic>? response =
        await sendRequest('POST', 'guard/$_savedCode/visit_point/$number');
    if (response == null || !response['success']) {
      print("Error occured");
      print(response);
    } else {
      setState(() {
        visitStorage.addVisit(
            Visit(Point.fromJson(response['point']), response['created_at']));
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
                                      style: TextStyle(
                                          fontSize: 25,
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center),
                                ),
                              ),
                              Expanded(
                                  child: Container(
                                child: Stack(
                                  children: [
                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: VisitListWidget(
                                        storage: visitStorage,
                                        code: _savedCode!,
                                      ),
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
                                                Theme.of(context).canvasColor,
                                                Theme.of(context)
                                                    .canvasColor
                                                    .withOpacity(0)
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
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      toolbarHeight: 65,
                                    ),
                                    body: Container(
                                      color: Theme.of(context).canvasColor,
                                      child: SafeArea(
                                        child: Stack(
                                          children: [
                                            MobileScanner(
                                              controller: MobileScannerController(
                                                detectionSpeed: DetectionSpeed.noDuplicates,
                                              ),
                                              onDetect: (BarcodeCapture capture) async {
                                                if (capture.barcodes.isEmpty) return;
                                                final barcode = capture.barcodes.first;
                                                final String? value = barcode.rawValue;
                                                if (value == null) return;

                                                _sendVisit(value);
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                            Align(
                                              alignment: Alignment.bottomCenter,
                                              child: Container(
                                                width: double.infinity,
                                                color: Colors.black54,
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                child: const Text(
                                                  'Отсканируйте QR код',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(color: Colors.white, fontSize: 16),
                                                ),
                                              ),
                                            ),
                                          ],
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
                    ))
                  ],
                ),
        ),
      ),
    );
  }
}
