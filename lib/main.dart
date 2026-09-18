import 'package:flutter/material.dart';
import 'services/low_signal_controller.dart';
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
    return AnimatedBuilder(
      animation: LowSignalController.instance,
      builder: (context, _) {
        final isLowSignal = LowSignalController.instance.isLowSignalMode;
        return MaterialApp(
          title: 'Saahat',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.lowSignalDarkTheme,
          themeMode: isLowSignal ? ThemeMode.dark : ThemeMode.light,
          home: const MainNavigationShell(),
        );
      },
    );
  }
}
