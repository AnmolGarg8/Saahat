import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/low_signal_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/pulsing_sos_button.dart';
import '../widgets/saarthi_floating_button.dart';
import '../widgets/saarthi_chat_sheet.dart';
import 'home_screen.dart';
import 'find_route_screen.dart';
import 'share_eta_screen.dart';
import 'community_notes_screen.dart';
import 'about_screen.dart';
import 'sos_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    LowSignalController.instance.addListener(_onLowSignalStateChanged);
  }

  @override
  void dispose() {
    LowSignalController.instance.removeListener(_onLowSignalStateChanged);
    super.dispose();
  }

  void _onLowSignalStateChanged() {
    if (mounted) setState(() {});
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openSosScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SosScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLowSignal = LowSignalController.instance.isLowSignalMode;

    final screens = [
      HomeScreen(
        onPlanJourney: () => _onTabSelected(1),
      ),
      FindRouteScreen(key: ValueKey('find_route_$isLowSignal')),
      ShareEtaScreen(key: ValueKey('share_eta_$isLowSignal')),
      CommunityNotesScreen(key: ValueKey('community_notes_$isLowSignal')),
      AboutScreen(key: ValueKey('about_$isLowSignal')),
    ];

    return Scaffold(
      backgroundColor: isLowSignal ? AppTheme.lowSignalBg : AppTheme.softLavenderBg,
      body: SafeArea(
        child: Column(
          children: [
            // Persistent Low Signal Mode Banner
            if (isLowSignal)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppTheme.lowSignalYellow,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.signal_cellular_alt_1_bar_rounded, color: Colors.black, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'LOW SIGNAL & BATTERY MODE: ON',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => LowSignalController.instance.setLowSignalMode(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: Text(
                        'Turn Off',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.lowSignalYellow,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Active Tab View
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: screens,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, left: 32.0, right: 0.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SaarthiFloatingButton(
              onTap: () => SaarthiChatSheet.show(context),
            ),
            PulsingSosButton(
              onTap: _openSosScreen,
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isLowSignal ? Colors.black : Colors.white,
          border: isLowSignal
              ? const Border(top: BorderSide(color: AppTheme.lowSignalBorder, width: 1.5))
              : null,
          boxShadow: isLowSignal
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
        ),
        child: BottomNavigationBar(
          backgroundColor: isLowSignal ? Colors.black : Colors.white,
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
          selectedItemColor: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
          unselectedItemColor: isLowSignal ? const Color(0xFF9E9E9E) : const Color(0xFF94A3B8),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined),
              activeIcon: Icon(Icons.location_on),
              label: 'Find Route',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.send_outlined),
              activeIcon: Icon(Icons.send),
              label: 'Share ETA',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Notes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shield_outlined),
              activeIcon: Icon(Icons.shield),
              label: 'About',
            ),
          ],
        ),
      ),
    );
  }
}
