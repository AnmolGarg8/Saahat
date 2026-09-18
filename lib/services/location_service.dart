import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';
import '../models/place_location.dart';

class LocationService {
  /// Requests GPS location and checks permissions.
  /// Throws descriptive exceptions for user feedback if denied/disabled.
  static Future<PlaceLocation> getCurrentDeviceLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied. Please enable them in App Settings.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );

    // Attempt reverse geocoding with user's Reverse Geocoding API key
    String placeName = 'Current Location';
    String secondary = 'GPS (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';

    try {
      final resolved = await reverseGeocode(position.latitude, position.longitude);
      if (resolved != null) {
        placeName = resolved['name'] ?? placeName;
        secondary = resolved['secondary'] ?? secondary;
      }
    } catch (_) {}

    return PlaceLocation(
      name: placeName,
      latitude: position.latitude,
      longitude: position.longitude,
      secondaryText: secondary,
    );
  }

  /// Reverse geocodes coordinates to a human-readable place name using Geoapify.
  static Future<Map<String, String>?> reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://api.geoapify.com/v1/geocode/reverse'
        '?lat=$lat&lon=$lon'
        '&apiKey=${ApiConfig.reverseGeocodingApiKey}',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>?;
        if (features != null && features.isNotEmpty) {
          final props = features.first['properties'] as Map<String, dynamic>? ?? {};
          final name = props['name'] as String? ??
              props['street'] as String? ??
              props['suburb'] as String? ??
              props['city'] as String? ??
              'Current Location';
          final formatted = props['formatted'] as String? ?? '';
          return {
            'name': name,
            'secondary': formatted.isNotEmpty ? formatted : 'GPS Device Location',
          };
        }
      }
    } catch (_) {}
    return null;
  }
}
