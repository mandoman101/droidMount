import 'package:flutter/material.dart';
import 'ui/home_page.dart';

class OpenClawDesktopApp extends StatelessWidget {
  const OpenClawDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DroidMount',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF00F2FE),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
