import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/low_signal_controller.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLowSignal =
        Theme.of(context).brightness == Brightness.dark || LowSignalController.instance.isLowSignalMode;

    return Scaffold(
      backgroundColor: isLowSignal ? AppTheme.lowSignalBg : AppTheme.softLavenderBg,
      appBar: AppBar(
        backgroundColor: isLowSignal ? AppTheme.lowSignalBg : AppTheme.softLavenderBg,
        foregroundColor: isLowSignal ? Colors.white : const Color(0xFF1E1E2D),
        title: const Text('About'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isLowSignal
                      ? AppTheme.lowSignalGreen.withValues(alpha: 0.2)
                      : AppTheme.accentTeal.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: isLowSignal ? Border.all(color: AppTheme.lowSignalGreen, width: 2) : null,
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 40,
                  color: isLowSignal ? AppTheme.lowSignalGreen : AppTheme.accentTeal,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'About Saahat',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isLowSignal ? Colors.white : const Color(0xFF1E1E2D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Empowering every journey with safety, security, and peace of mind.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isLowSignal ? const Color(0xFFB0B0C0) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
