import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_reader/services/notification_service.dart';
import 'package:qr_reader/universal_safe_area.dart';

import 'firebase_options.dart';
import 'login.dart';

const primaryColor = Color(0xFF006940);

void main() async {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: primaryColor,
      systemNavigationBarColor: primaryColor,
      systemNavigationBarDividerColor: primaryColor,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.light,
    ),
  );

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const FirebasePermissionGate());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final FlexSchemeColor customScheme = FlexSchemeColor.from(primary: primaryColor);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('ru'),
      themeMode: ThemeMode.light,
      title: 'Sostra',
      theme: FlexThemeData.light(colors: customScheme),
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (BuildContext context) {
          return Container(
            color: Theme.of(context).primaryColor,
            child: SafeArea(
              top: true,
              left: false,
              right: false,
              bottom: false,
              child: Container(
                color: Theme.of(context).canvasColor,
                child: SafeArea(
                  top: false,
                  left: false,
                  right: false,
                  bottom: true,
                  child: AuthChecker(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
