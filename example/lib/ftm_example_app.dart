import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

class FTMExampleApp extends StatelessWidget {
  const FTMExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const HomeScreen(),
    );
  }
}