import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/low_signal_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/low_signal_offline_view.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onPlanJourney;

  const HomeScreen({
    super.key,
    this.onPlanJourney,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation1;
  late Animation<Offset> _slideAnimation2;
  late Animation<Offset> _slideAnimation3;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnimation1 = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic),
    ));

    _slideAnimation2 = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
    ));

    _slideAnimation3 = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    ));

    _animController.forward();
    LowSignalController.instance.addListener(_onLowSignalChanged);
  }

  void _onLowSignalChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    LowSignalController.instance.removeListener(_onLowSignalChanged);
    _animController.dispose();
    super.dispose();
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLowSignal = LowSignalController.instance.isLowSignalMode;

    return Scaffold(
      backgroundColor: isLowSignal ? AppTheme.lowSignalBg : AppTheme.softLavenderBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Logo, Wordmark, Tagline, Low Signal Toggle & Profile Avatar
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: isLowSignal
                          ? null
                          : const LinearGradient(
                              colors: [
                                AppTheme.primaryPurple,
                                AppTheme.secondaryMagenta,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color: isLowSignal ? AppTheme.lowSignalYellow : null,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: isLowSignal
                          ? null
                          : [
                              BoxShadow(
                                color: AppTheme.primaryPurple.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                    ),
                    child: Icon(
                      Icons.explore_rounded,
                      color: isLowSignal ? Colors.black : Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Wordmark & Tagline
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Saahat',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            color: isLowSignal ? Colors.white : const Color(0xFF1E1E2D),
                          ),
                        ),
                        Text(
                          'Your journey. Your choice. Your confidence.',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Dedicated "Low Signal Mode" Toggle Pill
                  InkWell(
                    onTap: () => LowSignalController.instance.toggleLowSignalMode(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      decoration: BoxDecoration(
                        color: isLowSignal ? AppTheme.lowSignalYellow : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFFCBD5E1),
                          width: 1.5,
                        ),
                        boxShadow: isLowSignal
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLowSignal
                                ? Icons.signal_cellular_alt_1_bar_rounded
                                : Icons.signal_cellular_alt_rounded,
                            size: 15,
                            color: isLowSignal ? Colors.black : const Color(0xFF475569),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isLowSignal ? 'Low Signal: ON' : 'Low Signal',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isLowSignal ? Colors.black : const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Profile Avatar
                  GestureDetector(
                    onTap: _openProfile,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isLowSignal ? AppTheme.lowSignalCard : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isLowSignal ? AppTheme.lowSignalBorder : AppTheme.primaryPurple.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                        boxShadow: isLowSignal
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: isLowSignal ? Colors.white : AppTheme.primaryPurple,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // When Low Signal Mode is ON, prominently show the Offline Directions & Help Points panel
              if (isLowSignal) ...[
                const LowSignalOfflineView(),
                const SizedBox(height: 12),
              ],

              // Hero Banner Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryPurple,
                      const Color(0xFF8B5CF6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Headline
                    Text(
                      'Go beyond the fastest route.',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Subtext
                    Text(
                      'Saahat helps you choose a journey that fits the moment — with clearer options, useful journey signals, and support when you need it.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                    const SizedBox(height: 22),
                    // Prominent "Plan My Journey" Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: widget.onPlanJourney,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryPurple,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          shadowColor: Colors.transparent,
                        ),
                        icon: const Icon(
                          Icons.alt_route_rounded,
                          color: AppTheme.primaryPurple,
                          size: 22,
                        ),
                        label: Text(
                          'Plan My Journey',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: AppTheme.primaryPurple,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Section Title
              Text(
                'Why Saahat is different',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isLowSignal ? Colors.white : const Color(0xFF1E1E2D),
                ),
              ),
              const SizedBox(height: 14),

              // 3 Animated Highlight Cards
              _buildAnimatedCard(
                isLowSignal: isLowSignal,
                slideAnimation: _slideAnimation1,
                icon: Icons.wb_twilight_rounded,
                iconBgColor: isLowSignal ? AppTheme.lowSignalYellow.withValues(alpha: 0.2) : AppTheme.accentGold.withValues(alpha: 0.15),
                iconColor: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFFD99B00),
                title: 'Real conditions, not just distance',
                subtitle: 'lighting, footfall, transit, time-of-day',
              ),
              const SizedBox(height: 12),
              _buildAnimatedCard(
                isLowSignal: isLowSignal,
                slideAnimation: _slideAnimation2,
                icon: Icons.shield_outlined,
                iconBgColor: isLowSignal ? AppTheme.lowSignalCyan.withValues(alpha: 0.2) : AppTheme.secondaryMagenta.withValues(alpha: 0.12),
                iconColor: isLowSignal ? AppTheme.lowSignalCyan : AppTheme.secondaryMagenta,
                title: 'No live tracking, ever',
                subtitle: 'zero continuous location logs, one-time ETA updates only',
              ),
              const SizedBox(height: 12),
              _buildAnimatedCard(
                isLowSignal: isLowSignal,
                slideAnimation: _slideAnimation3,
                icon: Icons.balance_rounded,
                iconBgColor: isLowSignal ? AppTheme.lowSignalGreen.withValues(alpha: 0.2) : AppTheme.accentTeal.withValues(alpha: 0.12),
                iconColor: isLowSignal ? AppTheme.lowSignalGreen : AppTheme.accentTeal,
                title: 'We describe, we never judge an area',
                subtitle: 'objective indicators, no area stigma',
              ),

              // Bottom padding so nothing gets obscured by the floating SOS button
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard({
    required bool isLowSignal,
    required Animation<Offset> slideAnimation,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final cardContent = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isLowSignal ? AppTheme.lowSignalCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isLowSignal
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
        border: Border.all(
          color: isLowSignal ? AppTheme.lowSignalBorder : Colors.black.withValues(alpha: 0.04),
          width: isLowSignal ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isLowSignal ? Colors.white : const Color(0xFF1E1E2D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isLowSignal ? const Color(0xFFB0B0C0) : const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isLowSignal) {
      return cardContent;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: cardContent,
      ),
    );
  }
}
