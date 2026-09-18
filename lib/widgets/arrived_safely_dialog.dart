import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/trusted_contact.dart';
import '../services/eta_sharing_service.dart';
import '../theme/app_theme.dart';

/// Modal dialog with a satisfying completion animation when user taps "I've Arrived Safely".
class ArrivedSafelyDialog extends StatefulWidget {
  final TrustedContact? contact;
  final String routeName;
  final VoidCallback onDismiss;

  const ArrivedSafelyDialog({
    super.key,
    required this.contact,
    required this.routeName,
    required this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required TrustedContact? contact,
    required String routeName,
    required VoidCallback onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ArrivedSafelyDialog(
        contact: contact,
        routeName: routeName,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  State<ArrivedSafelyDialog> createState() => _ArrivedSafelyDialogState();
}

class _ArrivedSafelyDialogState extends State<ArrivedSafelyDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _sendArrivalSms() async {
    if (widget.contact == null) return;
    final message = EtaSharingService.formatArrivedSafelyMessage(
      contactName: widget.contact!.name,
    );
    await EtaSharingService.openSmsApp(
      phone: widget.contact!.phone,
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    final contact = widget.contact;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C2A8).withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Checkmark with Glowing Rings
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer pulsing glow ring
                      Container(
                        width: 120 * _glowAnimation.value,
                        height: 120 * _glowAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00C2A8).withValues(
                            alpha: 0.2 * (1 - _glowAnimation.value * 0.3),
                          ),
                        ),
                      ),
                      // Middle ring
                      Container(
                        width: 96 * _scaleAnimation.value,
                        height: 96 * _scaleAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00C2A8).withValues(alpha: 0.15),
                        ),
                      ),
                      // Core Icon Circle
                      Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF00E5C0), Color(0xFF00A38D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x6600C2A8),
                                blurRadius: 18,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 46,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 22),

              // Title
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      "You've Arrived Safely!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1E2D),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Journey via ${widget.routeName} completed.\nAll ETA notifications cleared.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Notify Contact Option (if contact exists)
              if (contact != null)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: contact.avatarColor,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            contact.initials,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notify ${contact.name}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E1E2D),
                                ),
                              ),
                              Text(
                                'Send "Arrived Safely" SMS',
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _sendArrivalSms,
                          style: TextButton.styleFrom(
                            backgroundColor: AppTheme.primaryPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.send_rounded, size: 12, color: Colors.white),
                          label: Text(
                            'SMS',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Done Button
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onDismiss();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C2A8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Done • Back to Trip',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
