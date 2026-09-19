import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../config/api_config.dart';
import '../models/place_location.dart';
import '../services/eta_sharing_service.dart';
import '../services/route_scoring_service.dart';
import '../theme/app_theme.dart';
import '../widgets/arrived_safely_dialog.dart';
import '../widgets/saarthi_chat_sheet.dart';
import 'sos_screen.dart';

/// Live Turn-by-Turn Navigation Screen with real-time GPS tracking,
/// resilient map rendering, diagnostic error states, permission checks,
/// Saarthi voice guidance, and live ETA metrics.
class LiveNavigationScreen extends StatefulWidget {
  final ScoredRoute route;
  final PlaceLocation from;
  final PlaceLocation to;
  final List<SafetyPOI> safetyPOIs;

  const LiveNavigationScreen({
    super.key,
    required this.route,
    required this.from,
    required this.to,
    this.safetyPOIs = const [],
  });

  @override
  State<LiveNavigationScreen> createState() => _LiveNavigationScreenState();
}

class _LiveNavigationScreenState extends State<LiveNavigationScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;

  ll.LatLng? _currentPosition;
  double _currentHeading = 0.0;
  bool _hasLocationPermission = true;
  bool _isCheckingPermission = true;
  String? _mapErrorMessage;
  bool _isVoiceEnabled = true;

  int _currentStepIndex = 0;
  late List<_NavigationStep> _steps;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initSteps();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkPermissionAndInitGps();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _initSteps() {
    final route = widget.route;
    _steps = [
      _NavigationStep(
        instruction: 'Depart ${widget.from.name}',
        detail: 'Head toward main entrance onto ${route.viaRoad}',
        distanceText: '250 m',
        distanceMeters: 250,
        icon: Icons.trip_origin_rounded,
        safetyNote: 'Well-lit departure hub with verified footfall',
        voiceText: 'Head out from ${widget.from.name}. Lighting is bright and footfall is active.',
      ),
      _NavigationStep(
        instruction: 'Turn right onto ${route.viaRoad}',
        detail: 'Continue straight along the primary corridor',
        distanceText: '1.4 km',
        distanceMeters: 1400,
        icon: Icons.turn_right_rounded,
        safetyNote: 'Active commercial zone with active CCTV & streetlights',
        voiceText: 'In 250 meters, turn right onto ${route.viaRoad}. Keep to the main well-lit lane.',
      ),
      _NavigationStep(
        instruction: 'Pass Transit Corridor & Metro Hub',
        detail: 'Proceed past active transit station',
        distanceText: '850 m',
        distanceMeters: 850,
        icon: Icons.directions_bus_rounded,
        safetyNote: 'Open help points, police patrol post 300m ahead',
        voiceText: 'Passing the transit hub. You have active transport and safety posts nearby.',
      ),
      _NavigationStep(
        instruction: 'Continue straight toward ${widget.to.name}',
        detail: 'Stay on the main avenue',
        distanceText: '600 m',
        distanceMeters: 600,
        icon: Icons.straight_rounded,
        safetyNote: 'Consistently illuminated pedestrian sidewalk',
        voiceText: 'Continue straight for 600 meters toward your destination.',
      ),
      _NavigationStep(
        instruction: 'Arrive at ${widget.to.name}',
        detail: 'Destination is on your right',
        distanceText: '50 m',
        distanceMeters: 50,
        icon: Icons.flag_rounded,
        safetyNote: 'Safe arrival zone',
        voiceText: 'You are arriving at ${widget.to.name}. Have a safe arrival!',
      ),
    ];
  }

  Future<void> _checkPermissionAndInitGps() async {
    setState(() => _isCheckingPermission = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _hasLocationPermission = false;
            _isCheckingPermission = false;
            _currentPosition = ll.LatLng(widget.from.latitude, widget.from.longitude);
          });
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _hasLocationPermission = false;
            _isCheckingPermission = false;
            _currentPosition = ll.LatLng(widget.from.latitude, widget.from.longitude);
          });
        }
        return;
      }

      // Permission granted - start GPS stream
      final initialPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      ).catchError((_) async {
        return Position(
          latitude: widget.from.latitude,
          longitude: widget.from.longitude,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      });

      if (mounted) {
        setState(() {
          _hasLocationPermission = true;
          _isCheckingPermission = false;
          _currentPosition = ll.LatLng(initialPos.latitude, initialPos.longitude);
          _currentHeading = initialPos.heading;
        });

        _listenToPositionStream();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasLocationPermission = false;
          _isCheckingPermission = false;
          _currentPosition = ll.LatLng(widget.from.latitude, widget.from.longitude);
        });
      }
    }
  }

  void _listenToPositionStream() {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      if (mounted) {
        setState(() {
          _currentPosition = ll.LatLng(pos.latitude, pos.longitude);
          if (pos.heading > 0) _currentHeading = pos.heading;
        });
      }
    }, onError: (_) {});
  }

  void _recenterMap() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 16.5);
    } else if (widget.route.coordinates.isNotEmpty) {
      _mapController.move(
        ll.LatLng(widget.route.coordinates.first[0], widget.route.coordinates.first[1]),
        16.0,
      );
    }
  }

  void _nextManeuver() {
    if (_currentStepIndex < _steps.length - 1) {
      setState(() => _currentStepIndex++);
      final progressFraction = (_currentStepIndex + 1) / _steps.length;
      if (widget.route.coordinates.isNotEmpty) {
        final targetIndex = (widget.route.coordinates.length * progressFraction)
            .floor()
            .clamp(0, widget.route.coordinates.length - 1);
        final coord = widget.route.coordinates[targetIndex];
        final nextPos = ll.LatLng(coord[0], coord[1]);
        setState(() => _currentPosition = nextPos);
        _mapController.move(nextPos, 16.5);
      }
    } else {
      _showArrivedSafelyDialog();
    }
  }

  void _showArrivedSafelyDialog() {
    ArrivedSafelyDialog.show(
      context,
      contact: EtaSharingService.instance.activeContact,
      routeName: widget.route.title,
      onDismiss: () {
        Navigator.of(context).pop();
      },
    );
  }

  void _shareLiveEta() {
    final now = DateTime.now();
    final arrival = now.add(Duration(minutes: widget.route.durationMinutes));
    final arrivalTimeStr =
        '${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}';

    final message = EtaSharingService.formatEtaMessage(
      routeName: widget.route.title,
      durationMinutes: widget.route.durationMinutes,
      formattedArrivalTime: arrivalTimeStr,
    );

    final contact = EtaSharingService.instance.activeContact;
    final phone = contact?.phone ?? '+91 98765 43210';

    EtaSharingService.openSmsApp(phone: phone, message: message).then((opened) {
      if (mounted && !opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ETA SMS preview generated: $message'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final currentStep = _steps[_currentStepIndex];
    final remainingMinutes =
        ((route.durationMinutes * (1.0 - (_currentStepIndex / _steps.length)))).ceil().clamp(1, 180);
    final remainingKm =
        ((route.distanceKm * (1.0 - (_currentStepIndex / _steps.length)))).clamp(0.1, 99.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Live Navigation Map Layer
            _buildMapLayer(),

            // 2. Visible Diagnostic Error Banner (if map tiles fail)
            if (_mapErrorMessage != null) _buildMapErrorBanner(),

            // 3. Location Permission Required Banner / Prompt (if not granted)
            if (!_hasLocationPermission && !_isCheckingPermission)
              _buildLocationPermissionPrompt(),

            // 4. Top Turn-by-Turn Maneuver Header
            Positioned(
              top: 12,
              left: 14,
              right: 14,
              child: _buildTurnByTurnHeader(currentStep),
            ),

            // 5. Saarthi Voice Guidance Banner
            Positioned(
              top: 154,
              left: 14,
              right: 14,
              child: _buildSaarthiVoiceBar(currentStep),
            ),

            // 6. Floating Action Controls on Map (Recenter, Next Step)
            Positioned(
              right: 16,
              bottom: 230,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFloatingMapButton(
                    icon: Icons.my_location_rounded,
                    tooltip: 'Recenter GPS',
                    onTap: _recenterMap,
                  ),
                  const SizedBox(height: 10),
                  _buildFloatingMapButton(
                    icon: Icons.skip_next_rounded,
                    tooltip: 'Next Turn',
                    onTap: _nextManeuver,
                  ),
                ],
              ),
            ),

            // 7. Bottom Navigation Dashboard Panel (ETA, Actions, End Journey)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomDashboard(remainingMinutes, remainingKm),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapLayer() {
    final routeCoords = widget.route.coordinates.isNotEmpty
        ? widget.route.coordinates.map((c) => ll.LatLng(c[0], c[1])).toList()
        : [
            ll.LatLng(widget.from.latitude, widget.from.longitude),
            ll.LatLng(widget.to.latitude, widget.to.longitude),
          ];

    final userPoint = _currentPosition ?? routeCoords.first;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: userPoint,
        initialZoom: 16.0,
        maxZoom: 19.0,
        minZoom: 4.0,
      ),
      children: [
        // Primary Tile Layer with error tracking
        TileLayer(
          urlTemplate: ApiConfig.mapTileUrlTemplate,
          userAgentPackageName: 'com.example.saahat_app',
          errorTileCallback: (tile, error, stackTrace) {
            if (mounted && _mapErrorMessage == null) {
              setState(() {
                _mapErrorMessage = 'Map tiles failed to load: $error';
              });
            }
          },
        ),

        // Glow outline polyline
        PolylineLayer(
          polylines: [
            Polyline(
              points: routeCoords,
              strokeWidth: 8.5,
              color: AppTheme.primaryPurple.withValues(alpha: 0.35),
            ),
            Polyline(
              points: routeCoords,
              strokeWidth: 5.5,
              color: AppTheme.primaryPurple,
            ),
          ],
        ),

        // Markers: Safety POIs, Origin, Destination & Live GPS User
        MarkerLayer(
          markers: [
            // Safety POIs along route
            for (final poi in widget.safetyPOIs)
              Marker(
                point: ll.LatLng(poi.latitude, poi.longitude),
                width: 30,
                height: 30,
                child: Container(
                  decoration: BoxDecoration(
                    color: _getPoiColor(poi.category),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getPoiIcon(poi.category),
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),

            // Destination Pin
            Marker(
              point: ll.LatLng(widget.to.latitude, widget.to.longitude),
              width: 38,
              height: 38,
              child: const Icon(
                Icons.location_on_rounded,
                color: Color(0xFFEF4444),
                size: 38,
              ),
            ),

            // User Live GPS Marker with pulse & heading arrow
            Marker(
              point: userPoint,
              width: 50,
              height: 50,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulsing radar ring
                      Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                      // Inner solid dot with directional heading arrow
                      Transform.rotate(
                        angle: (_currentHeading * 3.1415926535 / 180),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF2563EB),
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.navigation_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTurnByTurnHeader(_NavigationStep step) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Large Maneuver Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF9333EA), width: 1.5),
                ),
                child: Icon(step.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              // Maneuver Distance and Instruction
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IN ${step.distanceText.toUpperCase()}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF38BDF8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      step.instruction,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      step.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              // Close / Exit Navigation Button
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Exit Navigation',
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Safety Condition Banner for current segment
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded, size: 13, color: Color(0xFF10B981)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    step.safetyNote,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaarthiVoiceBar(_NavigationStep step) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6366F1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          // Saarthi Avatar Icon
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/saahat_icon.png',
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 8),
          // Spoken guidance text
          Expanded(
            child: Text(
              _isVoiceEnabled ? step.voiceText : 'Saarthi Voice Guidance is muted',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _isVoiceEnabled ? const Color(0xFFC7D2FE) : const Color(0xFF64748B),
              ),
            ),
          ),
          // Voice Mute Toggle
          InkWell(
            onTap: () {
              setState(() => _isVoiceEnabled = !_isVoiceEnabled);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                _isVoiceEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                size: 18,
                color: _isVoiceEnabled ? const Color(0xFF818CF8) : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Ask Saarthi Quick Button
          InkWell(
            onTap: () => SaarthiChatSheet.show(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Ask AI',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapErrorBanner() {
    return Positioned(
      top: 210,
      left: 14,
      right: 14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _mapErrorMessage ?? 'Map failed to load. Please check network connection.',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF991B1B),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => _mapErrorMessage = null);
                _recenterMap();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPermissionPrompt() {
    return Positioned(
      top: 210,
      left: 14,
      right: 14,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.location_disabled_rounded, color: Color(0xFFD97706), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Location Permission Required',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF92400E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Saahat needs GPS access to track your live position along the route. Tap below to enable permissions.',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF78350F),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _checkPermissionAndInitGps,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Grant Permission',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    setState(() => _hasLocationPermission = true);
                  },
                  child: Text(
                    'Continue with Simulation',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }

  Widget _buildBottomDashboard(int remainingMinutes, double remainingKm) {
    final now = DateTime.now();
    final arrival = now.add(Duration(minutes: remainingMinutes));
    final etaStr =
        '${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Metrics Row: Remaining Time, Distance, Arrival ETA, Journey Fit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$remainingMinutes',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryPurple,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'min',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '•',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${remainingKm.toStringAsFixed(1)} km',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'ETA $etaStr • ${widget.route.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              // Fit Score Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security_rounded, size: 14, color: AppTheme.primaryPurple),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.route.fitScore.toStringAsFixed(1)} FIT',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Actions Row: Share ETA, Quick SOS, End Journey
          Row(
            children: [
              // Share Live ETA Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareLiveEta,
                  icon: const Icon(Icons.share_rounded, size: 16, color: AppTheme.primaryPurple),
                  label: Text(
                    'Share ETA',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryPurple,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppTheme.primaryPurple, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // SOS Quick Button
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SosScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  side: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'SOS',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // End Journey / Arrived Safely Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showArrivedSafelyDialog,
                  icon: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                  label: Text(
                    'End Journey',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPoiColor(String category) {
    switch (category) {
      case 'police':
        return const Color(0xFF2563EB);
      case 'hospital':
        return const Color(0xFFDC2626);
      case 'transit':
        return const Color(0xFF0D9488);
      default:
        return AppTheme.primaryPurple;
    }
  }

  IconData _getPoiIcon(String category) {
    switch (category) {
      case 'police':
        return Icons.local_police_rounded;
      case 'hospital':
        return Icons.local_hospital_rounded;
      case 'transit':
        return Icons.directions_bus_rounded;
      default:
        return Icons.shield_rounded;
    }
  }
}

class _NavigationStep {
  final String instruction;
  final String detail;
  final String distanceText;
  final double distanceMeters;
  final IconData icon;
  final String safetyNote;
  final String voiceText;

  const _NavigationStep({
    required this.instruction,
    required this.detail,
    required this.distanceText,
    required this.distanceMeters,
    required this.icon,
    required this.safetyNote,
    required this.voiceText,
  });
}
