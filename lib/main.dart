import 'package:flutter/material.dart';
import 'package:thryfto/pages/login_page.dart';

void main() {
  runApp(const ThriftoApp());
}

class ThriftoApp extends StatelessWidget {
  const ThriftoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thryfto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      ),
      home: const LoginScreen(),
    );
  }
}
