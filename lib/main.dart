import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SaahatApp());
}

class SaahatApp extends StatelessWidget {
  const SaahatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saahat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigationShell(),
    );
  }
}
