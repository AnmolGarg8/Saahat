import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/low_signal_controller.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _callHelpline(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch phone dialer for $number'),
              backgroundColor: AppTheme.sosCoralRed,
            ),
          );
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isLowSignal =
        Theme.of(context).brightness == Brightness.dark || LowSignalController.instance.isLowSignalMode;

    final bgColor = isLowSignal ? AppTheme.lowSignalBg : AppTheme.softLavenderBg;
    final cardBg = isLowSignal ? const Color(0xFF14141E) : Colors.white;
    final borderColor = isLowSignal ? AppTheme.lowSignalBorder : const Color(0xFFE2E8F0);
    final primaryTextColor = isLowSignal ? AppTheme.lowSignalText : const Color(0xFF1E1E2D);
    final subtextColor = isLowSignal ? const Color(0xFFB0B0C0) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isLowSignal ? AppTheme.lowSignalBg : Colors.white,
        foregroundColor: primaryTextColor,
        elevation: isLowSignal ? 0 : 0.5,
        title: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'About Saahat',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hero Brand Logo Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: isLowSignal
                    ? null
                    : [
                        BoxShadow(
                          color: AppTheme.primaryPurple.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  Image.asset(
                    isLowSignal
                        ? 'assets/images/saahat_logo_dark.png'
                        : 'assets/images/saahat_logo_transparent.png',
                    height: 52,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Har Safar Mein Raahat',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Empowering everyday journeys across Indian cities with transparent safety signals, route awareness, and offline continuity — built with absolute privacy at its core.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      height: 1.5,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4 Safety Pillars
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'OUR CORE PILLARS',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 10),

            _buildPillarCard(
              icon: Icons.shield_outlined,
              iconColor: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFF10B981),
              title: 'Zero Continuous Tracking',
              description:
                  'We never log, track, or record your live journey in the background. ETA updates are shared point-in-time by SMS only when you choose.',
              cardBg: cardBg,
              borderColor: borderColor,
              primaryTextColor: primaryTextColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 10),

            _buildPillarCard(
              icon: Icons.wb_sunny_outlined,
              iconColor: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFFF59E0B),
              title: 'Objective Signals, No Stigma',
              description:
                  'Routes are scored on verifiable conditions: streetlights, verified footfall, active transit hubs, and time-of-day. We describe conditions, never stigmatize areas.',
              cardBg: cardBg,
              borderColor: borderColor,
              primaryTextColor: primaryTextColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 10),

            _buildPillarCard(
              icon: Icons.signal_cellular_off_rounded,
              iconColor: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.accentTeal,
              title: 'Low Signal & Battery Mode',
              description:
                  'Full offline continuity with cached step-by-step navigation, local emergency points, and OLED true-dark battery preservation.',
              cardBg: cardBg,
              borderColor: borderColor,
              primaryTextColor: primaryTextColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 10),

            _buildPillarCard(
              icon: Icons.people_outline_rounded,
              iconColor: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
              title: 'Community Verified Intelligence',
              description:
                  '100% anonymous crowdsourced observations from travelers on active lighting, police assistance booths, and safe transit gates.',
              cardBg: cardBg,
              borderColor: borderColor,
              primaryTextColor: primaryTextColor,
              subtextColor: subtextColor,
            ),

            const SizedBox(height: 20),

            // Emergency Helplines Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'NATIONAL EMERGENCY HELPLINES',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLowSignal ? const Color(0xFF14141E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isLowSignal ? AppTheme.lowSignalBorder : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  _buildHelplineRow(
                    context: context,
                    title: 'National Emergency Helpline',
                    number: '112',
                    badge: '24/7 All-in-One',
                    isLowSignal: isLowSignal,
                    primaryTextColor: primaryTextColor,
                  ),
                  const Divider(height: 20),
                  _buildHelplineRow(
                    context: context,
                    title: 'Women Helpline (National)',
                    number: '1091',
                    badge: 'Toll-free',
                    isLowSignal: isLowSignal,
                    primaryTextColor: primaryTextColor,
                  ),
                  const Divider(height: 20),
                  _buildHelplineRow(
                    context: context,
                    title: 'Police Emergency',
                    number: '100',
                    badge: 'Direct Control',
                    isLowSignal: isLowSignal,
                    primaryTextColor: primaryTextColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // App Version & Credits
            Text(
              'Saahat v1.0.0 (Production Candidate)',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: subtextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Made with care for women, students, and night commuters.',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: subtextColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required Color cardBg,
    required Color borderColor,
    required Color primaryTextColor,
    required Color subtextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    height: 1.4,
                    color: subtextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelplineRow({
    required BuildContext context,
    required String title,
    required String number,
    required String badge,
    required bool isLowSignal,
    required Color primaryTextColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    'Dial $number',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isLowSignal
                          ? AppTheme.lowSignalYellow.withValues(alpha: 0.15)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _callHelpline(context, number),
          icon: const Icon(Icons.call_rounded, size: 14),
          label: Text(number),
          style: ElevatedButton.styleFrom(
            backgroundColor: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFF10B981),
            foregroundColor: isLowSignal ? Colors.black : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}
