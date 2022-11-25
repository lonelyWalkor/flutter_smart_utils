import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastManager {
  static show(String? msg) {
    if (null == msg) return;
    if (msg.isEmpty) return;
    if (msg.length > 100) {
      msg = msg.substring(0, 100);
    }
    Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 14.0
    );
  }
}