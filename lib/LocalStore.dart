import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  static SharedPreferences? prefs;

  static init() async {
    if (prefs != null) return;
    prefs = await SharedPreferences.getInstance();
  }

  static setInt(String key, int value) async {
    await init();
    prefs!.setInt(key, value);
  }

  static Future<int> getInt(String key) async {
    await init();
    return prefs!.getInt(key) ?? 0;
  }

  static setItem(String key, String value) async {
    await init();
    prefs?.setString(key, value);
  }

  static Future<String?> getItem(String key) async {
    await init();
    if (!prefs!.containsKey(key)) return null;
    return prefs!.getString(key);
  }

  static Future<bool> removeItem(String key) async {
    await init();
    if (!prefs!.containsKey(key)) return true;
    prefs!.remove(key);
    return true;
  }

  static getItemToInt(String key, [int defVal = 0]) async {
    String? printNumLocal = await LocalStore.getItem(key);
    int printNum = defVal;
    if (printNumLocal != null) {
      try {
        printNum = int.parse(printNumLocal);
      } catch (e, stack) {
        debugPrint(e.toString() + stack.toString());
      }
    }
    return printNum;
  }

  static getItemToDouble(String key, [double defVal = 0]) async {
    String? printNumLocal = await LocalStore.getItem(key);
    double printNum = defVal;
    if (printNumLocal != null) {
      try {
        printNum = double.parse(printNumLocal);
      } catch (e, stack) {
        debugPrint(e.toString() + stack.toString());
      }
    }
    return printNum;
  }

}