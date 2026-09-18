import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/place_location.dart';
import '../theme/app_theme.dart';

class RouteResultsScreen extends StatelessWidget {
  final PlaceLocation from;
  final PlaceLocation to;
  final TimeOfDay? departureTime;
  final bool isLeavingNow;

  const RouteResultsScreen({
    super.key,
    required this.from,
    required this.to,
    this.departureTime,
    this.isLeavingNow = true,
  });

  @override
  Widget build(BuildContext context) {
    final timeDisplay = isLeavingNow
        ? 'Leaving now'
        : 'Depart at ${departureTime?.format(context) ?? 'Selected time'}';

    return Scaffold(
      backgroundColor: AppTheme.softLavenderBg,
      appBar: AppBar(
        title: const Text('Route Results'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route summary card
            Container(
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.circle, color: AppTheme.primaryPurple, size: 14),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          from.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1E2D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 6.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 20,
                        width: 2,
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppTheme.secondaryMagenta, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          to.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1E2D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text(
                        timeDisplay,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const Icon(Icons.alt_route_rounded, size: 48, color: AppTheme.primaryPurple),
                  const SizedBox(height: 12),
                  Text(
                    'Route scoring & comparison',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E1E2D),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Full route comparison cards will be built here in the next step.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
