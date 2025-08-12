import 'dart:html' as html;                  // for Notification API
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../main.dart';

class FirebasePermissionGate extends StatefulWidget {
  const FirebasePermissionGate({super.key});

  @override
  State<FirebasePermissionGate> createState() => _FirebasePermissionGateState();
}

class _FirebasePermissionGateState extends State<FirebasePermissionGate> {
  bool _initialized = false;
  bool _granted = false;
  bool _unsupported = false;
  bool _showApp = false;
  String? _error;
  final _messaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (!html.Notification.supported) {
      setState(() {
        _unsupported = true;
      });
      return;
    }

    try {
      await Firebase.initializeApp();
    } catch (e) {
      setState(() {
        _unsupported = true;
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
    if (!html.Notification.supported) {
      return;
    }
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
          _unsupported = true;
          _granted = false;
        });
      }
    } catch (e) {
      setState(() {
        _granted = false;
        _unsupported = true;
        _error = e.toString();
      });
    }
    setState(() {
      _initialized = true;
    });
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
    if (_showApp || _granted) {
      return MyApp();
    }

    if (_unsupported) {
      return MaterialApp(
          locale: const Locale('ru'),
          home: Scaffold(
              appBar: AppBar(title: const Text('Необходимо разрешение')),
              body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,

                    children: [
                        const Text(
                          'Уведомления не поддеживаются вашим браузером. Подпишитесь на них в телеграм боте',
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                      onPressed: () => setState(() {
                        _showApp = true;
                      }),
                      child: const Text('Понятно'),
                      ),
                    ],
                  ),
              ),
          ),
      );
    }

    if (!_initialized) {
      return const MaterialApp(
        locale: Locale('ru'),
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
        locale: const Locale('ru'),
        home: Scaffold(
          appBar: AppBar(title: const Text('Необходимо разрешение')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,

              children: [
                const Text(
                  'Для работы приложения нужно разрешение на отправку уведомлений',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _request,
                  child: const Text('Запросить разрешение'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => {
                    setState(() {
                      _showApp = true;
                    })
                  },
                  child: const Text('Продолжить без уведомлений'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 20),
                  Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
        ),
      );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(FirebasePermissionGate());
}
