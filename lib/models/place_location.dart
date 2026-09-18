class PlaceLocation {
  final String name;
  final double latitude;
  final double longitude;
  final String? placeId;
  final String? secondaryText;

  const PlaceLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.placeId,
    this.secondaryText,
  });

  @override
  String toString() => '$name ($latitude, $longitude)';
}

class PlaceSuggestion {
  final String placeId;
  final String primaryText;
  final String secondaryText;
  final String fullDescription;
  final double? latitude;
  final double? longitude;

  const PlaceSuggestion({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
    required this.fullDescription,
    this.latitude,
    this.longitude,
  });

  /// Factory for Google Places Autocomplete prediction JSON
  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final structured = json['structured_formatting'] as Map<String, dynamic>?;
    return PlaceSuggestion(
      placeId: json['place_id'] as String? ?? '',
      primaryText: structured?['main_text'] as String? ?? json['description'] as String? ?? '',
      secondaryText: structured?['secondary_text'] as String? ?? '',
      fullDescription: json['description'] as String? ?? '',
    );
  }

  /// Factory for Geoapify Autocomplete Feature JSON
  factory PlaceSuggestion.fromGeoapify(Map<String, dynamic> feature) {
    final props = feature['properties'] as Map<String, dynamic>? ?? {};
    final name = props['name'] as String? ?? props['address_line1'] as String? ?? '';
    final secondary = props['address_line2'] as String? ?? props['formatted'] as String? ?? '';
    final full = props['formatted'] as String? ?? name;
    final placeId = props['place_id'] as String? ?? '';
    final lat = (props['lat'] as num?)?.toDouble();
    final lon = (props['lon'] as num?)?.toDouble();

    return PlaceSuggestion(
      placeId: placeId,
      primaryText: name.isNotEmpty ? name : full,
      secondaryText: secondary,
      fullDescription: full,
      latitude: lat,
      longitude: lon,
    );
  }
}
