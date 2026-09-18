/// Central configuration file for external APIs in Saahat.
///
/// HOW TO CONFIGURE YOUR GOOGLE MAPS API KEY:
/// 1. Replace the string below with your real Google Maps API Key:
///    `static const String googleMapsApiKey = 'AIzaSy...';`
/// 2. Also add the key to `android/local.properties`:
///    `MAPS_API_KEY=AIzaSy...`
class ApiConfig {
  /// Place your Google Maps & Google Places API key here:
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'YOUR_GOOGLE_MAPS_API_KEY_HERE',
  );

  /// Helper to check if a real key has been entered.
  static bool get hasValidKey =>
      googleMapsApiKey.isNotEmpty &&
      googleMapsApiKey != 'YOUR_GOOGLE_MAPS_API_KEY_HERE';
}
