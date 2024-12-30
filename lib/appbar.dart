import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:qr_reader/settings.dart';

AppBar CustomAppBar(BuildContext context, [VoidCallback? onLogout]) {
  return AppBar(
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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SettingsScreen(
                logoutCallback: onLogout,
              ),
            ),
          );
        },
      )
    ],
  );
}
