import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';

void main() {
  runApp(const OjhaPhatSigonApp());
}

class OjhaPhatSigonApp extends StatelessWidget {
  const OjhaPhatSigonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ojha Paath Sigi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B7A6E), // calm teal — easy on the eyes for a learning app
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}
