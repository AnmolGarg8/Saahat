import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const SaahatApp());
}

class SaahatApp extends StatelessWidget {
  const SaahatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saahat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C2BD9),
          primary: const Color(0xFF6C2BD9),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
