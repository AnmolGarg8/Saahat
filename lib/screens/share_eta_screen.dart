import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/low_signal_controller.dart';
import '../theme/app_theme.dart';

class ShareEtaScreen extends StatelessWidget {
  const ShareEtaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLowSignal =
        Theme.of(context).brightness == Brightness.dark || LowSignalController.instance.isLowSignalMode;

    return Scaffold(
      backgroundColor: isLowSignal ? AppTheme.lowSignalBg : AppTheme.softLavenderBg,
      appBar: AppBar(
        backgroundColor: isLowSignal ? AppTheme.lowSignalBg : AppTheme.softLavenderBg,
        foregroundColor: isLowSignal ? Colors.white : const Color(0xFF1E1E2D),
        title: const Text('Share ETA'),
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
                      ? AppTheme.lowSignalCyan.withValues(alpha: 0.2)
                      : AppTheme.secondaryMagenta.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: isLowSignal ? Border.all(color: AppTheme.lowSignalCyan, width: 2) : null,
                ),
                child: Icon(
                  Icons.send_outlined,
                  size: 38,
                  color: isLowSignal ? AppTheme.lowSignalCyan : AppTheme.secondaryMagenta,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Share Your Trip & ETA',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isLowSignal ? Colors.white : const Color(0xFF1E1E2D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Live location sharing and trusted contact alerts will appear here.',
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
