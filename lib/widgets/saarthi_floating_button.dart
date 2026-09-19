import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/low_signal_controller.dart';
import '../theme/app_theme.dart';

/// Floating chat bubble button positioned at the bottom-left opposite the SOS button.
class SaarthiFloatingButton extends StatefulWidget {
  final VoidCallback onTap;

  const SaarthiFloatingButton({
    super.key,
    required this.onTap,
  });

  @override
  State<SaarthiFloatingButton> createState() => _SaarthiFloatingButtonState();
}

class _SaarthiFloatingButtonState extends State<SaarthiFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLowSignal = LowSignalController.instance.isLowSignalMode;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isLowSignal ? 1.0 : _scaleAnimation.value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(30),
              splashColor: isLowSignal ? Colors.black : Colors.white24,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  gradient: isLowSignal
                      ? null
                      : const LinearGradient(
                          colors: [
                            Color(0xFF6C5CE7),
                            Color(0xFF5344C9),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: isLowSignal ? AppTheme.lowSignalYellow : null,
                  borderRadius: BorderRadius.circular(28),
                  border: isLowSignal
                      ? Border.all(color: Colors.white, width: 2)
                      : Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: isLowSignal
                      ? [
                          const BoxShadow(
                            color: Colors.black,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: const Color(0xFF6C5CE7).withValues(alpha: 0.45),
                            blurRadius: 14,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.chat_bubble_rounded,
                          color: isLowSignal ? Colors.black : Colors.white,
                          size: 22,
                        ),
                        Positioned(
                          top: -3,
                          right: -3,
                          child: Icon(
                            Icons.auto_awesome,
                            color: isLowSignal ? const Color(0xFF990000) : const Color(0xFFFFD166),
                            size: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Saarthi',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: isLowSignal ? Colors.black : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
