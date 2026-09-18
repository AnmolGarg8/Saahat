import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/api_config.dart';
import '../models/place_location.dart';
import '../services/location_service.dart';
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

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  static const LatLng _initialCenter = LatLng(28.6139, 77.2090); // Delhi NCR default center

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
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _fromFocusNode.dispose();
    _toFocusNode.dispose();
    _mapController?.dispose();
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

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(loc.latitude, loc.longitude),
            zoom: 14.5,
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Using Current Location (${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)})'),
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
    final updated = <Marker>{};

    if (_fromLocation != null) {
      updated.add(
        Marker(
          markerId: const MarkerId('from_pin'),
          position: LatLng(_fromLocation!.latitude, _fromLocation!.longitude),
          infoWindow: InfoWindow(title: 'From: ${_fromLocation!.name}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        ),
      );
    }

    if (_toLocation != null) {
      updated.add(
        Marker(
          markerId: const MarkerId('to_pin'),
          position: LatLng(_toLocation!.latitude, _toLocation!.longitude),
          infoWindow: InfoWindow(title: 'To: ${_toLocation!.name}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        ),
      );
    }

    setState(() {
      _markers.clear();
      _markers.addAll(updated);
    });

    if (_fromLocation != null && _toLocation != null) {
      _fitMapToPins(_fromLocation!, _toLocation!);
    } else if (_fromLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_fromLocation!.latitude, _fromLocation!.longitude),
            zoom: 13.5,
          ),
        ),
      );
    } else if (_toLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_toLocation!.latitude, _toLocation!.longitude),
            zoom: 13.5,
          ),
        ),
      );
    }
  }

  void _fitMapToPins(PlaceLocation from, PlaceLocation to) {
    final southWest = LatLng(
      from.latitude < to.latitude ? from.latitude : to.latitude,
      from.longitude < to.longitude ? from.longitude : to.longitude,
    );
    final northEast = LatLng(
      from.latitude > to.latitude ? from.latitude : to.latitude,
      from.longitude > to.longitude ? from.longitude : to.longitude,
    );

    final bounds = LatLngBounds(southwest: southWest, northeast: northEast);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 70),
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
    return Scaffold(
      backgroundColor: AppTheme.softLavenderBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar / Search Form Container
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
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
                          color: const Color(0xFF1E1E2D),
                        ),
                      ),
                      const Spacer(),
                      if (!ApiConfig.hasValidKey)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGold.withValues(alpha: 0.15),
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
                    iconColor: AppTheme.primaryPurple,
                    isLoading: _isSearchingFrom,
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
                          : const Icon(Icons.my_location_rounded, size: 15, color: AppTheme.primaryPurple),
                      label: Text(
                        'Current',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryPurple,
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
                    iconColor: AppTheme.secondaryMagenta,
                    isLoading: _isSearchingTo,
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
                            color: _isLeavingNow ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                        selected: _isLeavingNow,
                        selectedColor: AppTheme.primaryPurple,
                        backgroundColor: const Color(0xFFF1F5F9),
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
                        avatar: const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.primaryPurple),
                        label: Text(
                          !_isLeavingNow && _departureTime != null
                              ? _departureTime!.format(context)
                              : 'Set time',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: !_isLeavingNow ? AppTheme.primaryPurple : const Color(0xFF475569),
                          ),
                        ),
                        backgroundColor: !_isLeavingNow ? AppTheme.primaryPurple.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
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
                        backgroundColor: AppTheme.primaryPurple,
                        foregroundColor: Colors.white,
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
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 16),
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
                  GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: _initialCenter,
                      zoom: 12.0,
                    ),
                    markers: _markers,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: true,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      if (_markers.isNotEmpty) {
                        _updateMapMarkers();
                      }
                    },
                  ),

                  // Visual overlay banner if API key is in placeholder mode
                  if (!ApiConfig.hasValidKey)
                    Positioned(
                      top: 10,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.vpn_key_outlined, size: 18, color: AppTheme.primaryPurple),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Google Maps Key configured in lib/config/api_config.dart',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF1E1E2D),
                                ),
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
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focusNode.hasFocus ? AppTheme.primaryPurple : const Color(0xFFE2E8F0),
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
                color: const Color(0xFF1E1E2D),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF94A3B8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (trailing != null) trailing,
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
        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
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
}
