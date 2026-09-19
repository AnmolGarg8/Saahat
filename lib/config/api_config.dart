/// Central configuration file for external APIs in Saahat.
///
/// Contains all 8 dedicated API keys for mapping, geocoding, autocomplete,
/// places, routing, reverse geocoding, place details, and static maps.
class ApiConfig {
  /// Map Tiles API Key (Geoapify Map Tiles)
  static const String mapTilesApiKey = 'be88317e15454d96ada9462341bce371';

  /// Geocoding API Key (Geoapify Geocoding Search)
  static const String geocodingApiKey = '1f79260d36974e08b3bbf55e7e7ac7f2';

  /// Autocomplete API Key (Geoapify Autocomplete)
  static const String autocompleteApiKey = '9290498e4b5d471ca6df13746961d590';

  /// Places API Key (Geoapify Places / Points of Interest)
  static const String placesApiKey = '514f88ec38bf42eb8385500b152bf738';

  /// Routing API Key (Geoapify Routing / ETA)
  static const String routingApiKey = '4057e1e893234b9aa6bc972ff540b18c';

  /// Reverse Geocoding API Key (Geoapify Reverse Geocoding)
  static const String reverseGeocodingApiKey = 'e2890656524f4405b015d43a764588ce';

  /// Place Details API Key (Geoapify Place Details)
  static const String placeDetailsApiKey = '31a55d09eb5b44d2a0256593dc541576';

  /// Static Map API Key (Geoapify Static Map)
  static const String staticMapApiKey = '3b7c42f03f774fef9e1530076cfcda12';

  /// Backwards-compatible Google Maps / fallback key
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: mapTilesApiKey,
  );

  /// OpenAI API Key for Saarthi Chatbot (injected via --dart-define or runtime setter)
  static String openAiApiKey = const String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  /// Anthropic API Key for Saarthi Chatbot
  static String anthropicApiKey = const String.fromEnvironment(
    'ANTHROPIC_API_KEY',
    defaultValue: '',
  );

  /// Selected AI Provider ('openai' or 'anthropic')
  static String aiProvider = 'openai';

  /// Helper to check if real keys are configured.
  static bool get hasValidKey =>
      autocompleteApiKey.isNotEmpty &&
      autocompleteApiKey != 'YOUR_GOOGLE_MAPS_API_KEY_HERE';

  /// Helper to get Geoapify tile URL template
  static String get mapTileUrlTemplate =>
      'https://maps.geoapify.com/v1/tile/osm-bright/{z}/{x}/{y}.png?apiKey=$mapTilesApiKey';

  /// Helper to construct a static map image URL
  static String getStaticMapUrl({
    required double latitude,
    required double longitude,
    int zoom = 14,
    int width = 600,
    int height = 400,
  }) {
    return 'https://maps.geoapify.com/v1/staticmap?style=osm-bright&width=$width&height=$height&center=lonlat:$longitude,$latitude&zoom=$zoom&marker=lonlat:$longitude,$latitude;color:%236c2bd9;size:medium&apiKey=$staticMapApiKey';
  }
}

