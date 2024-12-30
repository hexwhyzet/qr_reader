import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  FlexSchemeColor customScheme = FlexSchemeColor.from(primary: primaryColor);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sostra',
      theme: FlexThemeData.light(colors: customScheme),
      darkTheme: FlexThemeData.dark(colors: customScheme),
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
