import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/low_signal_controller.dart';
import '../theme/app_theme.dart';

class CommunityNotesScreen extends StatelessWidget {
  const CommunityNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLowSignal =
        Theme.of(context).brightness == Brightness.dark || LowSignalController.instance.isLowSignalMode;

    return Scaffold(
      backgroundColor: isLowSignal ? AppTheme.lowSignalBg : AppTheme.softLavenderBg,
      appBar: AppBar(
        backgroundColor: isLowSignal ? AppTheme.lowSignalBg : AppTheme.softLavenderBg,
        foregroundColor: isLowSignal ? Colors.white : const Color(0xFF1E1E2D),
        title: const Text('Community Notes'),
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
                      ? AppTheme.lowSignalYellow.withValues(alpha: 0.2)
                      : AppTheme.accentGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: isLowSignal ? Border.all(color: AppTheme.lowSignalYellow, width: 2) : null,
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 38,
                  color: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFFD99B00),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Community Notes',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isLowSignal ? Colors.white : const Color(0xFF1E1E2D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Crowdsourced safety alerts and community reports will appear here.',
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
