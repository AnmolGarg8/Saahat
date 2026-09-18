import 'package:geolocator/geolocator.dart';
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

    return PlaceLocation(
      name: 'Current Location',
      latitude: position.latitude,
      longitude: position.longitude,
      secondaryText: 'GPS Device Location',
    );
  }
}
