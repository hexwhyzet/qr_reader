import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

void raiseFlushbar(context, bool isSuccess, String message) {
  Flushbar(
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

void raiseSuccessFlushbar(context, String message) {
  raiseFlushbar(context, true, message);
}

void raiseErrorFlushbar(context, String message) {
  raiseFlushbar(context, false, message);
}
