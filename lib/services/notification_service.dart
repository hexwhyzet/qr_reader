import 'dart:html' as html;                  // for Notification API
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../main.dart';
import '../request.dart';

class FirebasePermissionGate extends StatefulWidget {
  @override
  _FirebasePermissionGateState createState() => _FirebasePermissionGateState();
}

class _FirebasePermissionGateState extends State<FirebasePermissionGate> {
  bool _initialized = false;
  bool _granted = false;
  String? _error;
  final _messaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }

    if (html.Notification.permission == 'granted') {
      setState(() {
        _granted = true;
      });
    }

    setState(() {
      _initialized = true;
    });
  }

  Future<void> _request() async {
    try {
      final permission = await html.Notification.requestPermission();
      if (permission == 'granted') {
        final messaging = FirebaseMessaging.instance;
        final token = await messaging.getToken();

        print('FCM Token: $token');
        setState(() {
          _granted = true;
        });
        _setupMessageHandlers();
      } else {
        setState(() {
          _granted = false;
        });
      }
    } catch (e) {
      setState(() {
        _initialized = true;
        _granted = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _setupMessageHandlers() async {
    //foreground message
    FirebaseMessaging.onMessage.listen((message) {
      showNotification(message);
    });

    // background message
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // opened app
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    if (message.data['type'] == 'chat') {
      // open chat screen
    }
  }

  Future<void> showNotification(RemoteMessage message) async {
    final notif = message.notification;
    if (notif != null) {
      final sw = html.window.navigator.serviceWorker;
      if (sw != null) {
        final swReg = await sw.ready;
        await swReg.showNotification(
          notif.title ?? '',
            {
              'body': notif.body,
              'icon': '@mipmap/ic_launcher',
              'data': message.data,
            }
        );
      } else {
        html.Notification(notif.title ?? '',
            body: notif.body,
            icon: '@mipmap/ic_launcher');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!_granted) {
      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: Text('Необходимо разрешение')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,

              children: [
                Text(
                  'Для работы приложения нужно разрешение на отправку уведомлений',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _request,
                  child: Text('Запросить разрешение'),
                ),
                if (_error != null) ...[
                  SizedBox(height: 20),
                  Text('Error: $_error', style: TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return MyApp();
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(FirebasePermissionGate());
}
