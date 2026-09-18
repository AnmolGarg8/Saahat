import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../config/api_config.dart';
import '../models/place_location.dart';
import '../services/location_service.dart';
import '../services/low_signal_controller.dart';
import '../services/places_service.dart';
import '../theme/app_theme.dart';
import 'route_results_screen.dart';

class FindRouteScreen extends StatefulWidget {
  const FindRouteScreen({super.key});

  @override
  State<FindRouteScreen> createState() => _FindRouteScreenState();
}

class _FindRouteScreenState extends State<FindRouteScreen> {
  final PlacesService _placesService = PlacesService();

  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  final FocusNode _fromFocusNode = FocusNode();
  final FocusNode _toFocusNode = FocusNode();

  PlaceLocation? _fromLocation;
  PlaceLocation? _toLocation;

  List<PlaceSuggestion> _fromSuggestions = [];
  List<PlaceSuggestion> _toSuggestions = [];

  bool _isSearchingFrom = false;
  bool _isSearchingTo = false;
  bool _isLoadingGps = false;

  bool _isLeavingNow = true;
  TimeOfDay? _departureTime;

  final MapController _mapController = MapController();

  static const ll.LatLng _initialCenter = ll.LatLng(28.6139, 77.2090); // Delhi NCR default center

  @override
  void initState() {
    super.initState();

    _fromController.addListener(_onFromTextChanged);
    _toController.addListener(_onToTextChanged);

    _fromFocusNode.addListener(() {
      if (!_fromFocusNode.hasFocus) {
        setState(() {
          _fromSuggestions = [];
        });
      }
    });

    _toFocusNode.addListener(() {
      if (!_toFocusNode.hasFocus) {
        setState(() {
          _toSuggestions = [];
        });
      }
    });

    LowSignalController.instance.addListener(_onLowSignalChanged);
  }

  void _onLowSignalChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    LowSignalController.instance.removeListener(_onLowSignalChanged);
    _fromController.dispose();
    _toController.dispose();
    _fromFocusNode.dispose();
    _toFocusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onFromTextChanged() async {
    final query = _fromController.text;
    if (query.trim().length < 2) {
      if (_fromSuggestions.isNotEmpty) {
        setState(() => _fromSuggestions = []);
      }
      return;
    }

    setState(() => _isSearchingFrom = true);
    final results = await _placesService.getAutocomplete(query);
    if (mounted && _fromFocusNode.hasFocus) {
      setState(() {
        _fromSuggestions = results;
        _isSearchingFrom = false;
      });
    }
  }

  void _onToTextChanged() async {
    final query = _toController.text;
    if (query.trim().length < 2) {
      if (_toSuggestions.isNotEmpty) {
        setState(() => _toSuggestions = []);
      }
      return;
    }

    setState(() => _isSearchingTo = true);
    final results = await _placesService.getAutocomplete(query);
    if (mounted && _toFocusNode.hasFocus) {
      setState(() {
        _toSuggestions = results;
        _isSearchingTo = false;
      });
    }
  }

  Future<void> _selectFromSuggestion(PlaceSuggestion suggestion) async {
    FocusScope.of(context).unfocus();
    _fromFocusNode.unfocus();
    _fromController.text = suggestion.primaryText;
    setState(() => _fromSuggestions = []);

    final details = await _placesService.getPlaceDetails(suggestion);
    if (details != null && mounted) {
      setState(() {
        _fromLocation = details;
        _updateMapMarkers();
      });
    }
  }

  Future<void> _selectToSuggestion(PlaceSuggestion suggestion) async {
    FocusScope.of(context).unfocus();
    _toFocusNode.unfocus();
    _toController.text = suggestion.primaryText;
    setState(() => _toSuggestions = []);

    final details = await _placesService.getPlaceDetails(suggestion);
    if (details != null && mounted) {
      setState(() {
        _toLocation = details;
        _updateMapMarkers();
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingGps = true);
    try {
      final loc = await LocationService.getCurrentDeviceLocation();
      if (!mounted) return;
      setState(() {
        _fromLocation = loc;
        _fromController.text = loc.name;
        _fromSuggestions = [];
        _updateMapMarkers();
      });

      _mapController.move(
        ll.LatLng(loc.latitude, loc.longitude),
        14.5,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Using Current Location: ${loc.name}'),
          backgroundColor: AppTheme.primaryPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingGps = false);
    }
  }

  void _updateMapMarkers() {
    setState(() {});

    if (_fromLocation != null && _toLocation != null) {
      _fitMapToPins(_fromLocation!, _toLocation!);
    } else if (_fromLocation != null) {
      _mapController.move(
        ll.LatLng(_fromLocation!.latitude, _fromLocation!.longitude),
        13.5,
      );
    } else if (_toLocation != null) {
      _mapController.move(
        ll.LatLng(_toLocation!.latitude, _toLocation!.longitude),
        13.5,
      );
    }
  }

  void _fitMapToPins(PlaceLocation from, PlaceLocation to) {
    final southWest = ll.LatLng(
      from.latitude < to.latitude ? from.latitude : to.latitude,
      from.longitude < to.longitude ? from.longitude : to.longitude,
    );
    final northEast = ll.LatLng(
      from.latitude > to.latitude ? from.latitude : to.latitude,
      from.longitude > to.longitude ? from.longitude : to.longitude,
    );

    final bounds = LatLngBounds(southWest, northEast);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(70),
      ),
    );
  }

  Future<void> _pickDepartureTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _departureTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryPurple,
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E1E2D),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _departureTime = picked;
        _isLeavingNow = false;
      });
    }
  }

  void _navigateToRouteResults() {
    if (_fromLocation == null || _toLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both From and To locations'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteResultsScreen(
          from: _fromLocation!,
          to: _toLocation!,
          departureTime: _departureTime,
          isLeavingNow: _isLeavingNow,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLowSignal = LowSignalController.instance.isLowSignalMode;

    return Scaffold(
      backgroundColor: isLowSignal ? AppTheme.lowSignalBg : AppTheme.softLavenderBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar / Search Form Container
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                color: isLowSignal ? AppTheme.lowSignalCard : Colors.white,
                border: isLowSignal
                    ? const Border(bottom: BorderSide(color: AppTheme.lowSignalBorder, width: 1.5))
                    : null,
                boxShadow: isLowSignal
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Bar
                  Row(
                    children: [
                      Text(
                        'Find Safe Route',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isLowSignal ? Colors.white : const Color(0xFF1E1E2D),
                        ),
                      ),
                      const Spacer(),
                      if (!ApiConfig.hasValidKey)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isLowSignal
                                ? AppTheme.lowSignalYellow.withValues(alpha: 0.15)
                                : AppTheme.accentGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.info_outline, size: 12, color: Color(0xFFD99B00)),
                              const SizedBox(width: 4),
                              Text(
                                'Config Key Ready',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFD99B00),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // "From" Input Field
                  _buildSearchInputField(
                    controller: _fromController,
                    focusNode: _fromFocusNode,
                    label: 'From (Origin)',
                    hint: 'Enter pickup or starting place...',
                    icon: Icons.circle,
                    iconColor: isLowSignal ? AppTheme.lowSignalCyan : AppTheme.primaryPurple,
                    isLoading: _isSearchingFrom,
                    isLowSignal: isLowSignal,
                    trailing: TextButton.icon(
                      onPressed: _isLoadingGps ? null : _useCurrentLocation,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: _isLoadingGps
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.my_location_rounded,
                              size: 15,
                              color: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
                            ),
                      label: Text(
                        'Current',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
                        ),
                      ),
                    ),
                  ),

                  // Suggestions for "From"
                  if (_fromSuggestions.isNotEmpty)
                    _buildSuggestionsDropdown(_fromSuggestions, _selectFromSuggestion),

                  const SizedBox(height: 8),

                  // "To" Input Field
                  _buildSearchInputField(
                    controller: _toController,
                    focusNode: _toFocusNode,
                    label: 'To (Destination)',
                    hint: 'Enter destination or landmark...',
                    icon: Icons.location_on,
                    iconColor: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.secondaryMagenta,
                    isLoading: _isSearchingTo,
                    isLowSignal: isLowSignal,
                  ),

                  // Suggestions for "To"
                  if (_toSuggestions.isNotEmpty)
                    _buildSuggestionsDropdown(_toSuggestions, _selectToSuggestion),

                  const SizedBox(height: 12),

                  // Time Selector Row
                  Row(
                    children: [
                      // Time Chips
                      ChoiceChip(
                        label: Text(
                          'Leaving now',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _isLeavingNow
                                ? (isLowSignal ? Colors.black : Colors.white)
                                : (isLowSignal ? Colors.white70 : const Color(0xFF475569)),
                          ),
                        ),
                        selected: _isLeavingNow,
                        selectedColor: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
                        backgroundColor: isLowSignal ? AppTheme.lowSignalBg : const Color(0xFFF1F5F9),
                        side: isLowSignal
                            ? BorderSide(color: _isLeavingNow ? AppTheme.lowSignalYellow : AppTheme.lowSignalBorder)
                            : null,
                        showCheckmark: false,
                        onSelected: (val) {
                          setState(() {
                            _isLeavingNow = true;
                            _departureTime = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: isLowSignal ? AppTheme.lowSignalCyan : AppTheme.primaryPurple,
                        ),
                        label: Text(
                          !_isLeavingNow && _departureTime != null
                              ? _departureTime!.format(context)
                              : 'Set time',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: !_isLeavingNow
                                ? (isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple)
                                : (isLowSignal ? Colors.white70 : const Color(0xFF475569)),
                          ),
                        ),
                        backgroundColor: !_isLeavingNow
                            ? (isLowSignal ? AppTheme.lowSignalYellow.withValues(alpha: 0.15) : AppTheme.primaryPurple.withValues(alpha: 0.12))
                            : (isLowSignal ? AppTheme.lowSignalBg : const Color(0xFFF1F5F9)),
                        side: isLowSignal ? const BorderSide(color: AppTheme.lowSignalBorder) : null,
                        onPressed: _pickDepartureTime,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // "Search Journey" Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _navigateToRouteResults,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
                        foregroundColor: isLowSignal ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Search Journey',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isLowSignal ? Colors.black : Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: isLowSignal ? Colors.black : Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Embedded Live Google Map
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: const MapOptions(
                      initialCenter: _initialCenter,
                      initialZoom: 12.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: ApiConfig.mapTileUrlTemplate,
                        userAgentPackageName: 'com.example.saahat_app',
                        maxZoom: 19,
                      ),
                      MarkerLayer(
                        markers: [
                          if (_fromLocation != null)
                            Marker(
                              point: ll.LatLng(_fromLocation!.latitude, _fromLocation!.longitude),
                              width: 140,
                              height: 52,
                              alignment: Alignment.topCenter,
                              child: _buildMapPin(
                                title: _fromLocation!.name,
                                color: AppTheme.primaryPurple,
                                icon: Icons.trip_origin_rounded,
                              ),
                            ),
                          if (_toLocation != null)
                            Marker(
                              point: ll.LatLng(_toLocation!.latitude, _toLocation!.longitude),
                              width: 140,
                              height: 52,
                              alignment: Alignment.topCenter,
                              child: _buildMapPin(
                                title: _toLocation!.name,
                                color: AppTheme.secondaryMagenta,
                                icon: Icons.location_on_rounded,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // Floating Map Controls
                  Positioned(
                    right: 16,
                    bottom: 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMapControlBtn(
                          icon: Icons.add,
                          tooltip: 'Zoom In',
                          onPressed: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom + 1,
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildMapControlBtn(
                          icon: Icons.remove,
                          tooltip: 'Zoom Out',
                          onPressed: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom - 1,
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildMapControlBtn(
                          icon: Icons.my_location_rounded,
                          tooltip: 'Center Location',
                          onPressed: _useCurrentLocation,
                        ),
                      ],
                    ),
                  ),

                  // Geoapify Live Map Tiles Status Badge
                  Positioned(
                    top: 10,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFF00C2A8).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00C2A8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Geoapify Live Map',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E1E2D),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildSearchInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required bool isLoading,
    bool isLowSignal = false,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isLowSignal ? AppTheme.lowSignalBg : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focusNode.hasFocus
              ? (isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple)
              : (isLowSignal ? AppTheme.lowSignalBorder : const Color(0xFFE2E8F0)),
          width: focusNode.hasFocus ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: icon == Icons.circle ? 10 : 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isLowSignal ? Colors.white : const Color(0xFF1E1E2D),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isLowSignal ? const Color(0xFF888899) : const Color(0xFF94A3B8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
                ),
              ),
            ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildSuggestionsDropdown(
    List<PlaceSuggestion> suggestions,
    Function(PlaceSuggestion) onSelect,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
        itemBuilder: (context, index) {
          final s = suggestions[index];
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.location_on_outlined, size: 18, color: AppTheme.primaryPurple),
            title: Text(
              s.primaryText,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E1E2D),
              ),
            ),
            subtitle: s.secondaryText.isNotEmpty
                ? Text(
                    s.secondaryText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  )
                : null,
            onTap: () => onSelect(s),
          );
        },
      ),
    );
  }

  Widget _buildMapPin({
    required String title,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E1E2D),
            ),
          ),
        ),
        Icon(icon, color: color, size: 26),
      ],
    );
  }

  Widget _buildMapControlBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shape: const CircleBorder(),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: const Color(0xFF1E1E2D)),
          ),
        ),
      ),
    );
  }
}

