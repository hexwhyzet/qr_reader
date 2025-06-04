import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:safe_area_insets/safe_area_insets.dart';

class UniversalSafeArea extends StatelessWidget {
  final Widget child;
  final bool left;
  final bool top;
  final bool right;
  final bool bottom;

  const UniversalSafeArea({
    super.key,
    required this.child,
    this.left = true,
    this.top = true,
    this.right = true,
    this.bottom = true,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return StreamBuilder<EdgeInsets>(
        stream: safeAreaInsetsStream,
        initialData: safeAreaInsets,
        builder: (context, snapshot) {
          final insets = snapshot.data ?? EdgeInsets.zero;
          return Padding(
            padding: EdgeInsets.only(
              left: left ? insets.left : 0,
              top: top ? insets.top : 0,
              right: right ? insets.right : 0,
              bottom: bottom ? insets.bottom : 0,
            ),
            child: child,
          );
        },
      );
    } else {
      return SafeArea(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        child: child,
      );
    }
  }
}
