import 'package:flutter/material.dart';

import 'package:mylib/mylib.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _response = '(please, wait)';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  void initPlatformState() {
    // sync call
    String response = nativeGreeting("Froggy McDale");

    setState(() {
      _response = response;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Rus t'),
        ),
        body: Center(
          child: Text(
            'Response:\n$_response\n',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
