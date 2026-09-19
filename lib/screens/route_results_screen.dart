import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../config/api_config.dart';
import '../models/place_location.dart';
import '../services/offline_cache_service.dart';
import '../services/places_service.dart';
import '../services/route_scoring_service.dart';
import '../services/routing_service.dart';
import '../services/saarthi_ai_service.dart';
import '../theme/app_theme.dart';
import '../widgets/saarthi_chat_sheet.dart';
import '../widgets/saarthi_floating_button.dart';
import 'live_navigation_screen.dart';

class RouteResultsScreen extends StatefulWidget {
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
  State<RouteResultsScreen> createState() => _RouteResultsScreenState();
}

class _RouteResultsScreenState extends State<RouteResultsScreen> {
  final RoutingService _routingService = RoutingService();
  final PlacesService _placesService = PlacesService();
  final MapController _mapController = MapController();
  final GlobalKey _mapRepaintBoundaryKey = GlobalKey();
  final Map<String, String> _downloadedRouteSizes = {};
  bool _isDownloading = false;

  final ScrollController _scrollController = ScrollController();
  double _saarthiOpacity = 1.0;
  Timer? _scrollStopTimer;

  List<ScoredRoute> _routes = [];
  List<SafetyPOI> _safetyPOIs = [];
  String? _selectedRouteId;
  final Set<String> _expandedRouteIds = {};

  bool _isLoading = true;
  bool _showSafetyPOIs = true;
  late TimeOfDayPeriod _timePeriod;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _timePeriod = RouteScoringService.resolveTimePeriod(
      widget.departureTime,
      widget.isLeavingNow,
    );
    _loadRoutesAndSafetyPOIs();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.isScrollingNotifier.value) {
      if (_saarthiOpacity != 0.2) {
        setState(() => _saarthiOpacity = 0.2);
      }
    }
    _scrollStopTimer?.cancel();
    _scrollStopTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted && _saarthiOpacity != 1.0) {
        setState(() => _saarthiOpacity = 1.0);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollStopTimer?.cancel();
    super.dispose();
  }

  void _navigateToLiveNavigation(ScoredRoute route) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveNavigationScreen(
          route: route,
          from: widget.from,
          to: widget.to,
          safetyPOIs: _safetyPOIs,
        ),
      ),
    );
  }

  Future<void> _loadRoutesAndSafetyPOIs() async {
    setState(() => _isLoading = true);

    try {
      // Compute midpoint to search for safety POIs along the journey
      final midLat = (widget.from.latitude + widget.to.latitude) / 2.0;
      final midLon = (widget.from.longitude + widget.to.longitude) / 2.0;

      // Concurrently fetch safety POIs and routes
      final results = await Future.wait([
        _placesService.getSafetyPOIsAlongRoute(lat: midLat, lon: midLon),
        _routingService.getMultiRouteOptions(
          from: widget.from,
          to: widget.to,
          timePeriod: _timePeriod,
        ),
      ]);

      if (!mounted) return;

      final pois = results[0] as List<SafetyPOI>;
      final routes = results[1] as List<ScoredRoute>;

      setState(() {
        _safetyPOIs = pois;
        _routes = routes;
        if (routes.isNotEmpty) {
          _selectedRouteId = routes.first.id;
          // Expand the best match by default
          _expandedRouteIds.add(routes.first.id);
          _persistRouteToOffline(routes.first);
          _updateSaarthiRouteContext(routes.first);
        }
        _isLoading = false;
      });

      // Fit map bounds once routes are loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitMapToRoute();
      });
    } catch (_) {
      if (!mounted) return;
      try {
        final fallbackRoutes = await _routingService.getMultiRouteOptions(
          from: widget.from,
          to: widget.to,
          timePeriod: _timePeriod,
        );
        setState(() {
          _routes = fallbackRoutes;
          if (_routes.isNotEmpty) {
            _selectedRouteId = _routes.first.id;
            _expandedRouteIds.add(_routes.first.id);
          }
          _isLoading = false;
        });
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<int> _persistRouteToOffline(ScoredRoute route, {Uint8List? mapBytes}) async {
    final cachedRoute = OfflineCachedRoute(
      origin: widget.from.name,
      destination: widget.to.name,
      routeTitle: route.title,
      durationText: '${route.durationMinutes} min',
      distanceText: '${route.distanceKm.toStringAsFixed(1)} km',
      fitScore: route.fitScore,
      contextTag: route.contextTag,
      steps: [
        OfflineRouteStep(
          instruction: 'Depart ${widget.from.name} toward main corridor',
          distanceText: '${(route.distanceKm * 0.25).toStringAsFixed(1)} km',
          iconType: 'depart',
          safetyNote: 'Well-lit departure zone with active streetlights',
        ),
        OfflineRouteStep(
          instruction: 'Proceed along ${route.viaRoad}',
          distanceText: '${(route.distanceKm * 0.5).toStringAsFixed(1)} km',
          iconType: 'straight',
          safetyNote: route.contextTag,
        ),
        OfflineRouteStep(
          instruction: 'Pass key transit corridor on ${route.viaRoad}',
          distanceText: '${(route.distanceKm * 0.15).toStringAsFixed(1)} km',
          iconType: 'transit',
          safetyNote: 'Monitored area with frequent bus and transit stops',
        ),
        OfflineRouteStep(
          instruction: 'Arrive at destination: ${widget.to.name}',
          distanceText: '${(route.distanceKm * 0.1).toStringAsFixed(1)} km',
          iconType: 'arrive',
          safetyNote: 'Designated brightly lit arrival zone',
        ),
      ],
      savedAt: DateTime.now(),
    );
    final totalSize = await OfflineCacheService.saveRouteForOffline(cachedRoute, mapImageBytes: mapBytes);

    if (_safetyPOIs.isNotEmpty) {
      final cachedPois = _safetyPOIs.map((p) => OfflineHelpPoint(
        name: p.name,
        category: p.category,
        address: p.address,
        distance: 'Along Route Corridor',
        phone: p.category == 'police' ? '+91-11-2669-1861' : p.category == 'hospital' ? '102' : '112',
      )).toList();
      await OfflineCacheService.saveHelpPoints(cachedPois);
    }
    return totalSize;
  }

  void _fitMapToRoute() {
    final southWest = ll.LatLng(
      widget.from.latitude < widget.to.latitude ? widget.from.latitude : widget.to.latitude,
      widget.from.longitude < widget.to.longitude ? widget.from.longitude : widget.to.longitude,
    );
    final northEast = ll.LatLng(
      widget.from.latitude > widget.to.latitude ? widget.from.latitude : widget.to.latitude,
      widget.from.longitude > widget.to.longitude ? widget.from.longitude : widget.to.longitude,
    );

    final bounds = LatLngBounds(southWest, northEast);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(40),
      ),
    );
  }

  void _selectRoute(String routeId) {
    setState(() {
      _selectedRouteId = routeId;
    });
    final match = _routes.where((r) => r.id == routeId);
    if (match.isNotEmpty) {
      _persistRouteToOffline(match.first);
      _updateSaarthiRouteContext(match.first);
    }
  }

  void _updateSaarthiRouteContext(ScoredRoute route) {
    SaarthiAiService.instance.setActiveRoute(
      ActiveRouteInfo(
        title: route.title,
        origin: widget.from.name,
        destination: widget.to.name,
        durationText: '${route.durationMinutes} min',
        distanceText: '${route.distanceKm.toStringAsFixed(1)} km',
        fitScore: route.fitScore,
        contextTag: route.contextTag,
        pros: route.pros,
        cons: route.cons,
      ),
    );
  }

  void _toggleExpand(String routeId) {
    setState(() {
      if (_expandedRouteIds.contains(routeId)) {
        _expandedRouteIds.remove(routeId);
      } else {
        _expandedRouteIds.add(routeId);
      }
    });
  }

  final Set<String> _downloadedRouteIds = {};

  Future<void> _downloadForOffline(ScoredRoute route) async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    Uint8List? mapBytes;
    try {
      final boundary = _mapRepaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          mapBytes = byteData.buffer.asUint8List();
        }
      }
    } catch (_) {}

    final totalBytes = await _persistRouteToOffline(route, mapBytes: mapBytes);
    final sizeFormatted = '${(totalBytes / 1024).round()} KB';

    if (!mounted) return;
    setState(() {
      _downloadedRouteIds.add(route.id);
      _downloadedRouteSizes[route.id] = sizeFormatted;
      _isDownloading = false;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route saved for offline use ✓',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${route.title} • Map snapshot & directions (~$sizeFormatted)',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00C2A8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeFormatted = widget.isLeavingNow
        ? 'Leaving now'
        : (widget.departureTime?.format(context) ?? 'Selected time');

    return Scaffold(
      backgroundColor: AppTheme.softLavenderBg,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, left: 16.0),
        child: AnimatedOpacity(
          opacity: _saarthiOpacity,
          duration: const Duration(milliseconds: 250),
          child: SaarthiFloatingButton(
            onTap: () => SaarthiChatSheet.show(context),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/saahat_icon.png',
                width: 24,
                height: 24,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Route Results',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E1E2D),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Evaluating safest journeys...',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E1E2D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Analyzing lighting, footfall & emergency points',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Origin / Destination & Time Summary Header Card
                  _buildJourneySummaryCard(timeFormatted),

                  // 2. Live Map with Colored Polylines & Safety POI markers
                  _buildLiveRouteMap(),

                  // 3. Safety POI Indicator Filter Bar
                  _buildSafetyPoiFilterBar(),

                  // 4. Route Selection Cards Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                    child: Row(
                      children: [
                        Text(
                          'Available Routes (${_routes.length})',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E1E2D),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.accentTeal.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Tap card to select',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF00897B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 5. List of Route Cards
                  ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _routes.length,
                    itemBuilder: (context, index) {
                      final route = _routes[index];
                      final isSelected = route.id == _selectedRouteId;
                      final isExpanded = _expandedRouteIds.contains(route.id);
                      return _buildRouteCard(route, isSelected, isExpanded);
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildJourneySummaryCard(String timeFormatted) {
    IconData timeIcon;
    Color timeColor;
    switch (_timePeriod) {
      case TimeOfDayPeriod.day:
        timeIcon = Icons.wb_sunny_rounded;
        timeColor = const Color(0xFFF59E0B);
        break;
      case TimeOfDayPeriod.evening:
        timeIcon = Icons.wb_twilight_rounded;
        timeColor = const Color(0xFF8B5CF6);
        break;
      case TimeOfDayPeriod.night:
        timeIcon = Icons.nightlight_round;
        timeColor = const Color(0xFF3B82F6);
        break;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Origin dot
              const Icon(Icons.circle, color: AppTheme.primaryPurple, size: 12),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.from.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E1E2D),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF94A3B8)),
              ),
              // Destination dot
              const Icon(Icons.location_on, color: AppTheme.secondaryMagenta, size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.to.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E1E2D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Time badge row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: timeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: timeColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(timeIcon, size: 13, color: timeColor),
                    const SizedBox(width: 5),
                    Text(
                      'Evaluated for ${_timePeriod.shortName}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: timeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '•  $timeFormatted',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveRouteMap() {
    final activeRoute = _routes.firstWhere(
      (r) => r.id == _selectedRouteId,
      orElse: () => _routes.first,
    );

    return RepaintBoundary(
      key: _mapRepaintBoundaryKey,
      child: Container(
        height: 250,
        margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: ll.LatLng(
                (widget.from.latitude + widget.to.latitude) / 2.0,
                (widget.from.longitude + widget.to.longitude) / 2.0,
              ),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: ApiConfig.mapTileUrlTemplate,
                userAgentPackageName: 'com.example.saahat_app',
                maxZoom: 19,
              ),

              // Route Polylines (Inactive routes in muted lavender, active in bold primary purple)
              PolylineLayer(
                polylines: [
                  for (final route in _routes)
                    if (route.id != _selectedRouteId && route.coordinates.isNotEmpty)
                      Polyline(
                        points: route.coordinates.map((c) => ll.LatLng(c[0], c[1])).toList(),
                        strokeWidth: 3.5,
                        color: const Color(0xFFC4B5FD).withValues(alpha: 0.8),
                      ),
                  // Active route rendered on top
                  if (activeRoute.coordinates.isNotEmpty)
                    Polyline(
                      points: activeRoute.coordinates.map((c) => ll.LatLng(c[0], c[1])).toList(),
                      strokeWidth: 5.5,
                      color: AppTheme.primaryPurple,
                    ),
                ],
              ),

              // Markers Layer: Origin, Destination, and Nearby Safety POIs
              MarkerLayer(
                markers: [
                  // Origin Marker
                  Marker(
                    point: ll.LatLng(widget.from.latitude, widget.from.longitude),
                    width: 90,
                    height: 42,
                    alignment: Alignment.topCenter,
                    child: _buildPinBadge(
                      title: widget.from.name,
                      color: AppTheme.primaryPurple,
                      icon: Icons.trip_origin_rounded,
                    ),
                  ),

                  // Destination Marker
                  Marker(
                    point: ll.LatLng(widget.to.latitude, widget.to.longitude),
                    width: 90,
                    height: 42,
                    alignment: Alignment.topCenter,
                    child: _buildPinBadge(
                      title: widget.to.name,
                      color: AppTheme.secondaryMagenta,
                      icon: Icons.location_on_rounded,
                    ),
                  ),

                  // Safety POI Markers (Police, Hospitals, Transit)
                  if (_showSafetyPOIs)
                    for (final poi in _safetyPOIs)
                      Marker(
                        point: ll.LatLng(poi.latitude, poi.longitude),
                        width: 34,
                        height: 34,
                        child: _buildSafetyPoiMarker(poi),
                      ),
                ],
              ),
            ],
          ),

          // Map action controls (Fit Bounds, POI toggle)
          Positioned(
            right: 12,
            bottom: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSmallMapBtn(
                  icon: Icons.center_focus_strong_rounded,
                  tooltip: 'Fit Route',
                  onTap: _fitMapToRoute,
                ),
                const SizedBox(height: 6),
                _buildSmallMapBtn(
                  icon: _showSafetyPOIs ? Icons.security_rounded : Icons.security_outlined,
                  tooltip: 'Toggle Safety Points',
                  isActive: _showSafetyPOIs,
                  onTap: () {
                    setState(() => _showSafetyPOIs = !_showSafetyPOIs);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildSafetyPoiFilterBar() {
    final policeCount = _safetyPOIs.where((p) => p.category == 'police').length;
    final hospitalCount = _safetyPOIs.where((p) => p.category == 'hospital').length;
    final transitCount = _safetyPOIs.where((p) => p.category == 'transit').length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Text(
            'Safety Points on Map:',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildPoiPill(
                icon: Icons.shield_rounded,
                label: 'Police ($policeCount)',
                color: const Color(0xFF2563EB),
              ),
              _buildPoiPill(
                icon: Icons.local_hospital_rounded,
                label: 'Hospital ($hospitalCount)',
                color: const Color(0xFFDC2626),
              ),
              _buildPoiPill(
                icon: Icons.directions_bus_rounded,
                label: 'Transit ($transitCount)',
                color: const Color(0xFF0D9488),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPoiPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRouteCard(ScoredRoute route, bool isSelected, bool isExpanded) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? AppTheme.primaryPurple : const Color(0xFFE2E8F0),
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppTheme.primaryPurple.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _selectRoute(route.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Badges Row (Best Match + Offline Download Button)
              Row(
                children: [
                  if (route.isBestMatch)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C2BD9), Color(0xFFFF4D8D)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 13, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'BEST MATCH',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  // Download for Offline Button
                  Builder(
                    builder: (context) {
                      final isDownloaded = _downloadedRouteIds.contains(route.id);
                      final sizeStr = _downloadedRouteSizes[route.id] ?? '~44 KB';
                      return Tooltip(
                        message: isDownloaded
                            ? 'Route saved for offline use ✓ ($sizeStr)'
                            : 'Download for Offline Use',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _downloadForOffline(route),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDownloaded ? 8 : 7,
                              vertical: isDownloaded ? 5 : 7,
                            ),
                            decoration: BoxDecoration(
                              color: isDownloaded
                                  ? const Color(0xFF00C2A8).withValues(alpha: 0.15)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: isDownloaded
                                  ? Border.all(color: const Color(0xFF00A892), width: 1)
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isDownloaded ? Icons.check_circle_rounded : Icons.download_rounded,
                                  size: 16,
                                  color: isDownloaded ? const Color(0xFF00A892) : const Color(0xFF475569),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isDownloaded ? 'Saved ($sizeStr)' : 'Offline',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isDownloaded ? const Color(0xFF00A892) : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 2. Title, Distance/Time, and Journey Fit Score Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E1E2D),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          route.viaRoad,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Distance and Time
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.primaryPurple),
                            const SizedBox(width: 4),
                            Text(
                              '${route.durationMinutes} min',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E1E2D),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.straighten_rounded, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              '${route.distanceKm.toStringAsFixed(1)} km',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Journey Fit Score Badge (e.g. 9.4 / 10)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryPurple.withValues(alpha: 0.1)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryPurple : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          route.fitScore.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? AppTheme.primaryPurple : const Color(0xFF1E1E2D),
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'FIT SCORE',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Context Tag
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insights_rounded, size: 14, color: AppTheme.primaryPurple),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        route.contextTag,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 4. Pros & Cons Lists
              _buildProsConsSection(route),

              const SizedBox(height: 12),

              // Prominent "Start Journey" Button (Full Width, Primary Purple)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToLiveNavigation(route),
                  icon: const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                  label: Text(
                    'Start Journey',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? AppTheme.primaryPurple : const Color(0xFF7C3AED),
                    elevation: isSelected ? 4 : 1,
                    shadowColor: AppTheme.primaryPurple.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 5. Expandable "Why this score?" Accordion
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _toggleExpand(route.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        size: 18,
                        color: AppTheme.primaryPurple,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Why this score?',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        isExpanded ? 'Hide metrics' : 'Show factor breakdown',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded Breakdown Drawer
              if (isExpanded)
                _buildScoreBreakdownDrawer(route.breakdown),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProsConsSection(ScoredRoute route) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pros
        for (final pro in route.pros)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pro,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Cons
        for (final con in route.cons)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFF59E0B)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    con,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildScoreBreakdownDrawer(RouteScoreBreakdown breakdown) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildScoreBarRow(
            label: 'Lighting Quality',
            score: breakdown.lightingScore,
            detail: breakdown.lightingDetail,
          ),
          const Divider(height: 16),
          _buildScoreBarRow(
            label: 'Pedestrian Footfall',
            score: breakdown.footfallScore,
            detail: breakdown.footfallDetail,
          ),
          const Divider(height: 16),
          _buildScoreBarRow(
            label: 'Public Transit Access',
            score: breakdown.transitScore,
            detail: breakdown.transitDetail,
          ),
          const Divider(height: 16),
          _buildScoreBarRow(
            label: 'Emergency / Help Points',
            score: breakdown.emergencyScore,
            detail: breakdown.emergencyDetail,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBarRow({
    required String label,
    required double score,
    required String detail,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E1E2D),
              ),
            ),
            Text(
              '${score.toStringAsFixed(1)} / 10',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 10.0,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(
              score >= 9.0
                  ? const Color(0xFF10B981)
                  : score >= 7.5
                      ? AppTheme.primaryPurple
                      : const Color(0xFFF59E0B),
            ),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          detail,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildPinBadge({
    required String title,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
              ),
            ],
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1E2D),
            ),
          ),
        ),
        Icon(icon, color: color, size: 20),
      ],
    );
  }

  Widget _buildSafetyPoiMarker(SafetyPOI poi) {
    Color bg;
    IconData icon;
    switch (poi.category) {
      case 'police':
        bg = const Color(0xFF2563EB);
        icon = Icons.shield_rounded;
        break;
      case 'hospital':
        bg = const Color(0xFFDC2626);
        icon = Icons.local_hospital_rounded;
        break;
      case 'transit':
      default:
        bg = const Color(0xFF0D9488);
        icon = Icons.directions_bus_rounded;
        break;
    }

    return Tooltip(
      message: poi.name,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildSmallMapBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shape: const CircleBorder(),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 18,
              color: isActive ? AppTheme.primaryPurple : const Color(0xFF1E1E2D),
            ),
          ),
        ),
      ),
    );
  }
}

