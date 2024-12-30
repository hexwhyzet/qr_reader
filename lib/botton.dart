import 'package:flutter/material.dart';

class StyledWideButton extends StatelessWidget {
  final Function()? onPressed;
  final String text;
  final Color bg;
  final Color fg;
  final double height;
  final double textWidth;

  const StyledWideButton(
      {Key,
      key,
      required this.text,
      required this.onPressed,
      required this.bg,
      required this.fg,
      required this.height,
      this.textWidth = 0.8})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: height,
      child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        double fontSize = (constraints.maxWidth * textWidth) / text.length;
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          onPressed: onPressed,
          child: Text(text,
              style:
                  TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
        );
      }),
    );
  }
}
