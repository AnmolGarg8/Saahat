import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/downloaded_route_viewer_screen.dart';
import '../screens/sos_screen.dart';
import '../services/offline_cache_service.dart';
import '../theme/app_theme.dart';

class LowSignalOfflineView extends StatefulWidget {
  final VoidCallback? onDisableMode;

  const LowSignalOfflineView({
    super.key,
    this.onDisableMode,
  });

  @override
  State<LowSignalOfflineView> createState() => _LowSignalOfflineViewState();
}

class _LowSignalOfflineViewState extends State<LowSignalOfflineView> {
  OfflineCachedRoute? _route;
  List<OfflineHelpPoint> _helpPoints = [];
  Uint8List? _mapSnapshotBytes;
  bool _isLoading = true;
  bool _isStepsExpanded = true;
  String? _lastCheckInText;

  @override
  void initState() {
    super.initState();
    _loadOfflineData();
  }

  Future<void> _loadOfflineData() async {
    final route = await OfflineCacheService.getLastCachedRoute();
    final helpPoints = await OfflineCacheService.getOfflineHelpPoints();
    final checkIn = await OfflineCacheService.getLastCheckIn();

    if (!mounted) return;
    setState(() {
      _route = route;
      _helpPoints = helpPoints;
      if (checkIn != null) {
        final parts = checkIn.split('|');
        if (parts.length >= 2) {
          final time = DateTime.tryParse(parts[1]);
          final timeStr = time != null
              ? "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}"
              : '';
          _lastCheckInText = "${parts[0]} at $timeStr (Saved locally)";
        }
      }
      _isLoading = false;
    });

    // Load static map snapshot asynchronously
    OfflineCacheService.getMapSnapshotBytes(route).then((bytes) {
      if (mounted) {
        setState(() => _mapSnapshotBytes = bytes);
      }
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

  Future<void> _onCheckInOk() async {
    await OfflineCacheService.recordCheckIn("I'm OK");
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    if (!mounted) return;
    setState(() {
      _lastCheckInText = "Safe status logged at $timeStr (Saved locally)";
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Logged: I'm OK at $timeStr. Stored offline & ready for SMS broadcast.",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.lowSignalGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _onNeedHelp() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SosScreen()),
    );
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
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppTheme.lowSignalYellow),
      );
    }

    final route = _route;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Battery Saver Info Card
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.lowSignalCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.lowSignalYellow, width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.battery_saver_rounded, color: AppTheme.lowSignalYellow, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'OLED true dark active. Map rendering & background requests suspended to preserve battery.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Large "I'm OK / Need Help" Compact Check-in Button Row
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.lowSignalCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.lowSignalBorder, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'OFFLINE CHECK-IN',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppTheme.lowSignalYellow,
                    ),
                  ),
                  if (_lastCheckInText != null)
                    Flexible(
                      child: Text(
                        _lastCheckInText!,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.lowSignalGreen,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // I'm OK Button
                  Expanded(
                    flex: 6,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _onCheckInOk,
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.black, size: 22),
                        label: Text(
                          "I'M OK",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Colors.black,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.lowSignalGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Need Help Button
                  Expanded(
                    flex: 5,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _onNeedHelp,
                        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                        label: Text(
                          "NEED HELP",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.lowSignalRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // View Downloaded Route Option Card
        if (route != null)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppTheme.lowSignalCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.lowSignalYellow, width: 1.5),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DownloadedRouteViewerScreen(
                        route: route,
                        helpPoints: _helpPoints,
                        mapSnapshotBytes: _mapSnapshotBytes,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.lowSignalYellow.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.lowSignalYellow, width: 1.2),
                        ),
                        child: const Icon(Icons.map_rounded, color: AppTheme.lowSignalYellow, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'VIEW DOWNLOADED ROUTE',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.lowSignalYellow,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppTheme.lowSignalGreen.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    route.formattedStorageSize,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.lowSignalGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${route.origin} → ${route.destination}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.lowSignalYellow, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Cached Route Directions Card
        if (route != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.lowSignalCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.lowSignalBorder, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Static Map Snapshot Image Banner
                if (_mapSnapshotBytes != null && _mapSnapshotBytes!.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DownloadedRouteViewerScreen(
                            route: route,
                            helpPoints: _helpPoints,
                            mapSnapshotBytes: _mapSnapshotBytes,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 175,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFF13131C),
                        border: Border(
                          bottom: BorderSide(color: AppTheme.lowSignalBorder, width: 1.5),
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(
                            _mapSnapshotBytes!,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Full View',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Card Header
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.lowSignalYellow.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.lowSignalYellow, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.download_done_rounded, color: AppTheme.lowSignalYellow, size: 14),
                                const SizedBox(width: 5),
                                Text(
                                  'SAVED FOR OFFLINE USE',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.lowSignalYellow,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "${route.durationText} • ${route.distanceText}",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        route.routeTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.trip_origin_rounded, color: AppTheme.lowSignalCyan, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              route.origin,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFB0B0C0)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppTheme.lowSignalYellow, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              route.destination,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppTheme.lowSignalBorder),

                // Collapsible Toggle for Steps
                InkWell(
                  onTap: () {
                    setState(() {
                      _isStepsExpanded = !_isStepsExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Step-by-Step Directions (${route.steps.length} steps)",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.lowSignalYellow,
                          ),
                        ),
                        Icon(
                          _isStepsExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.lowSignalYellow,
                        ),
                      ],
                    ),
                  ),
                ),

                // Step-by-Step Directions List
                if (_isStepsExpanded)
                  Container(
                    padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
                    child: Column(
                      children: List.generate(route.steps.length, (index) {
                        final step = route.steps[index];
                        final isLast = index == route.steps.length - 1;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Step Number & Icon
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isLast ? AppTheme.lowSignalGreen : AppTheme.lowSignalBorder,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    _getStepIcon(step.iconType),
                                    size: 16,
                                    color: isLast ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Step Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Step ${index + 1}",
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.lowSignalYellow,
                                          ),
                                        ),
                                        Text(
                                          step.distanceText,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFB0B0C0),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      step.instruction,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        height: 1.3,
                                      ),
                                    ),
                                    if (step.safetyNote != null && step.safetyNote!.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(Icons.shield_rounded, size: 12, color: AppTheme.lowSignalCyan),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              step.safetyNote!,
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
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
                    ),
                  ),
              ],
            ),
          ),

        // Nearby Help Points Card ("Saved for offline use")
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
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
                  Row(
                    children: [
                      const Icon(Icons.emergency_rounded, color: AppTheme.lowSignalYellow, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'NEARBY HELP POINTS',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppTheme.lowSignalYellow,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.lowSignalCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Saved for offline use',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lowSignalCyan,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._helpPoints.map((point) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101018),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.lowSignalBorder, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: point.category == 'police'
                              ? Colors.blue.withValues(alpha: 0.2)
                              : point.category == 'hospital'
                                  ? Colors.red.withValues(alpha: 0.2)
                                  : Colors.green.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getHelpPointIcon(point.category),
                          size: 20,
                          color: point.category == 'police'
                              ? Colors.lightBlueAccent
                              : point.category == 'hospital'
                                  ? AppTheme.lowSignalRed
                                  : AppTheme.lowSignalGreen,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              point.name,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "${point.distance} • ${point.address}",
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
                      // Call Button
                      IconButton(
                        onPressed: () => _makePhoneCall(point.phone),
                        icon: const Icon(Icons.call, color: AppTheme.lowSignalGreen, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.lowSignalGreen.withValues(alpha: 0.15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        tooltip: "Call ${point.name}",
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
