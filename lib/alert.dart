import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

Future<void> raiseFlushbar(context, bool isSuccess, String message) async {
  await Flushbar(
    flushbarPosition: FlushbarPosition.TOP,
    borderRadius: BorderRadius.circular(8),
    margin: EdgeInsets.all(8),
    backgroundColor: isSuccess ? Colors.green : Colors.red,
    duration: Duration(seconds: 3),
    messageText: Text(
      message,
      style: TextStyle(fontSize: 19, color: Colors.white),
    ),
  ).show(context);
}

Future<void> raiseSuccessFlushbar(context, String message) async {
  await raiseFlushbar(context, true, message);
}

Future<void> raiseErrorFlushbar(context, String message) async {
  await raiseFlushbar(context, false, message);
}
