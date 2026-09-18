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

  const PlaceSuggestion({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
    required this.fullDescription,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final structured = json['structured_formatting'] as Map<String, dynamic>?;
    return PlaceSuggestion(
      placeId: json['place_id'] as String? ?? '',
      primaryText: structured?['main_text'] as String? ?? json['description'] as String? ?? '',
      secondaryText: structured?['secondary_text'] as String? ?? '',
      fullDescription: json['description'] as String? ?? '',
    );
  }
}
