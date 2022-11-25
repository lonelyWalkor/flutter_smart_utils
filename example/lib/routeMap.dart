
import 'package:flutter/cupertino.dart';
import 'package:smart_utils/FullScreenScanner.dart';
import 'package:smart_utils/SmartWebview.dart';

var routeMap = <String, WidgetBuilder>{
  '/weapp': (BuildContext context) => SmartWebview(initialUrl: 'https://www.baidu.com',),
  '/': (BuildContext context) => const FullScreenScannerPage(),
};
