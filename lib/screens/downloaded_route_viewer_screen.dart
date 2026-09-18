import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/offline_cache_service.dart';
import '../theme/app_theme.dart';

class DownloadedRouteViewerScreen extends StatefulWidget {
  final OfflineCachedRoute route;
  final List<OfflineHelpPoint> helpPoints;
  final Uint8List? mapSnapshotBytes;

  const DownloadedRouteViewerScreen({
    super.key,
    required this.route,
    required this.helpPoints,
    this.mapSnapshotBytes,
  });

  @override
  State<DownloadedRouteViewerScreen> createState() => _DownloadedRouteViewerScreenState();
}

class _DownloadedRouteViewerScreenState extends State<DownloadedRouteViewerScreen> {
  Uint8List? _mapBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMapImage();
  }

  Future<void> _loadMapImage() async {
    if (widget.mapSnapshotBytes != null && widget.mapSnapshotBytes!.isNotEmpty) {
      setState(() {
        _mapBytes = widget.mapSnapshotBytes;
        _isLoading = false;
      });
      return;
    }

    final bytes = await OfflineCacheService.getMapSnapshotBytes(widget.route);
    if (!mounted) return;
    setState(() {
      _mapBytes = bytes;
      _isLoading = false;
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  IconData _getStepIcon(String type) {
    switch (type) {
      case 'depart':
        return Icons.trip_origin_rounded;
      case 'turn_left':
        return Icons.turn_left_rounded;
      case 'turn_right':
        return Icons.turn_right_rounded;
      case 'transit':
        return Icons.train_rounded;
      case 'arrive':
        return Icons.flag_rounded;
      default:
        return Icons.straight_rounded;
    }
  }

  IconData _getHelpPointIcon(String category) {
    switch (category) {
      case 'police':
        return Icons.local_police_rounded;
      case 'hospital':
        return Icons.local_hospital_rounded;
      case 'pharmacy_247':
        return Icons.local_pharmacy_rounded;
      default:
        return Icons.shield_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;

    return Scaffold(
      backgroundColor: AppTheme.lowSignalBg,
      appBar: AppBar(
        backgroundColor: AppTheme.lowSignalBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Downloaded Route',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.offline_pin_rounded, color: AppTheme.lowSignalGreen, size: 12),
                const SizedBox(width: 4),
                Text(
                  '100% Offline • ${route.formattedStorageSize}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lowSignalGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Static Map Snapshot Image Section
            Container(
              height: 240,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF13131C),
                border: Border(
                  bottom: BorderSide(color: AppTheme.lowSignalBorder, width: 1.5),
                ),
              ),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.lowSignalYellow),
                    )
                  : (_mapBytes != null && _mapBytes!.isNotEmpty)
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            InteractiveViewer(
                              maxScale: 3.0,
                              child: Image.memory(
                                _mapBytes!,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.lowSignalYellow, width: 1),
                                ),
                                child: Text(
                                  'Pinch to Zoom Snapshot',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.lowSignalYellow,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Text(
                            'Map snapshot cached locally',
                            style: GoogleFonts.poppins(color: Colors.white70),
                          ),
                        ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.lowSignalCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.lowSignalBorder, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              route.routeTitle,
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.lowSignalYellow.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.lowSignalYellow, width: 1),
                              ),
                              child: Text(
                                'Fit ${route.fitScore.toStringAsFixed(1)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.lowSignalYellow,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.trip_origin_rounded, color: AppTheme.lowSignalCyan, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                route.origin,
                                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFB0B0C0)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: AppTheme.lowSignalYellow, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                route.destination,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF13131C),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded, color: AppTheme.lowSignalYellow, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                route.durationText,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Icon(Icons.straighten_rounded, color: AppTheme.lowSignalCyan, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                route.distanceText,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Condition: ${route.contextTag}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.lowSignalCyan,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Step-by-Step Directions Header
                  Row(
                    children: [
                      const Icon(Icons.alt_route_rounded, color: AppTheme.lowSignalYellow, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Step-by-Step Directions (${route.steps.length} steps)',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Steps List
                  ...route.steps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final step = entry.value;
                    final isLast = index == route.steps.length - 1;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.lowSignalCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.lowSignalBorder, width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isLast
                                  ? AppTheme.lowSignalYellow.withValues(alpha: 0.2)
                                  : AppTheme.lowSignalBorder,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getStepIcon(step.iconType),
                              size: 18,
                              color: isLast ? AppTheme.lowSignalYellow : Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Step ${index + 1}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.lowSignalYellow,
                                      ),
                                    ),
                                    Text(
                                      step.distanceText,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFB0B0C0),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  step.instruction,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    height: 1.3,
                                  ),
                                ),
                                if (step.safetyNote != null && step.safetyNote!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.shield_outlined, size: 12, color: AppTheme.lowSignalCyan),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          step.safetyNote!,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: AppTheme.lowSignalCyan,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // Saved Help Points Section
                  if (widget.helpPoints.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.emergency_rounded, color: AppTheme.lowSignalYellow, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Nearby Help Points (Saved Offline)',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ...widget.helpPoints.map((poi) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.lowSignalCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.lowSignalBorder, width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: poi.category == 'police'
                                    ? const Color(0xFF2563EB).withValues(alpha: 0.25)
                                    : poi.category == 'hospital'
                                        ? const Color(0xFFDC2626).withValues(alpha: 0.25)
                                        : AppTheme.lowSignalGreen.withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getHelpPointIcon(poi.category),
                                color: poi.category == 'police'
                                    ? const Color(0xFF60A5FA)
                                    : poi.category == 'hospital'
                                        ? const Color(0xFFF87171)
                                        : AppTheme.lowSignalGreen,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    poi.name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '${poi.distance} • ${poi.address}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: const Color(0xFFB0B0C0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _makePhoneCall(poi.phone),
                              icon: const Icon(Icons.phone_in_talk_rounded, color: AppTheme.lowSignalGreen),
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.lowSignalGreen.withValues(alpha: 0.15),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
