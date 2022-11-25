
import 'package:flutter/material.dart';
import 'package:smart_utils_example/routeMap.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'smart-utils',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: routeMap,
    );
  }
}
