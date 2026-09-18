import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/place_location.dart';

class PlacesService {
  final http.Client _client;

  PlacesService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches live autocomplete suggestions using Google Places Autocomplete API.
  /// Matches small/local places, streets, establishments, and landmarks.
  Future<List<PlaceSuggestion>> getAutocomplete(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    if (!ApiConfig.hasValidKey) {
      return _getFallbackSuggestions(query);
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&key=${ApiConfig.googleMapsApiKey}'
        '&language=en',
      );

      final response = await _client.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String?;
        if (status == 'OK' || status == 'ZERO_RESULTS') {
          final predictions = (data['predictions'] as List<dynamic>? ?? []);
          return predictions
              .map((p) => PlaceSuggestion.fromJson(p as Map<String, dynamic>))
              .toList();
        }
      }
      return _getFallbackSuggestions(query);
    } catch (_) {
      return _getFallbackSuggestions(query);
    }
  }

  /// Fetches place geometry (latitude and longitude) from Google Place Details API.
  Future<PlaceLocation?> getPlaceDetails(PlaceSuggestion suggestion) async {
    if (!ApiConfig.hasValidKey) {
      return _getFallbackCoordinates(suggestion);
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${suggestion.placeId}'
        '&fields=name,geometry,formatted_address'
        '&key=${ApiConfig.googleMapsApiKey}',
      );

      final response = await _client.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'OK') {
          final result = data['result'] as Map<String, dynamic>;
          final geometry = result['geometry'] as Map<String, dynamic>?;
          final location = geometry?['location'] as Map<String, dynamic>?;

          if (location != null) {
            final lat = (location['lat'] as num).toDouble();
            final lng = (location['lng'] as num).toDouble();
            return PlaceLocation(
              name: suggestion.primaryText,
              latitude: lat,
              longitude: lng,
              placeId: suggestion.placeId,
              secondaryText: suggestion.secondaryText,
            );
          }
        }
      }
      return _getFallbackCoordinates(suggestion);
    } catch (_) {
      return _getFallbackCoordinates(suggestion);
    }
  }

  List<PlaceSuggestion> _getFallbackSuggestions(String query) {
    final lower = query.toLowerCase();
    final samplePlaces = [
      const PlaceSuggestion(
        placeId: 'del_cp',
        primaryText: 'Connaught Place',
        secondaryText: 'Central Delhi, New Delhi, India',
        fullDescription: 'Connaught Place, Central Delhi, New Delhi, India',
      ),
      const PlaceSuggestion(
        placeId: 'del_hzk',
        primaryText: 'Hauz Khas Village',
        secondaryText: 'South Delhi, New Delhi, India',
        fullDescription: 'Hauz Khas Village, South Delhi, New Delhi, India',
      ),
      const PlaceSuggestion(
        placeId: 'del_sec29',
        primaryText: 'Sector 29 Market',
        secondaryText: 'Gurugram, Haryana, India',
        fullDescription: 'Sector 29 Market, Gurugram, Haryana, India',
      ),
      const PlaceSuggestion(
        placeId: 'del_cyberhub',
        primaryText: 'DLF CyberHub',
        secondaryText: 'DLF Phase 2, Gurugram, India',
        fullDescription: 'DLF CyberHub, DLF Phase 2, Gurugram, India',
      ),
      const PlaceSuggestion(
        placeId: 'del_saket',
        primaryText: 'Select CITYWALK Mall',
        secondaryText: 'Saket District Centre, New Delhi',
        fullDescription: 'Select CITYWALK Mall, Saket District Centre, New Delhi',
      ),
      const PlaceSuggestion(
        placeId: 'del_noida18',
        primaryText: 'Atta Market, Sector 18',
        secondaryText: 'Noida, Uttar Pradesh, India',
        fullDescription: 'Atta Market, Sector 18, Noida, Uttar Pradesh, India',
      ),
      const PlaceSuggestion(
        placeId: 'del_aiims',
        primaryText: 'AIIMS Metro Station',
        secondaryText: 'Ansari Nagar, New Delhi',
        fullDescription: 'AIIMS Metro Station, Ansari Nagar, New Delhi',
      ),
      const PlaceSuggestion(
        placeId: 'del_iit',
        primaryText: 'IIT Delhi Main Gate',
        secondaryText: 'Hauz Khas, New Delhi',
        fullDescription: 'IIT Delhi Main Gate, Hauz Khas, New Delhi',
      ),
    ];

    final filtered = samplePlaces.where((p) {
      return p.primaryText.toLowerCase().contains(lower) ||
          p.secondaryText.toLowerCase().contains(lower) ||
          p.fullDescription.toLowerCase().contains(lower);
    }).toList();

    if (filtered.isEmpty) {
      return [
        PlaceSuggestion(
          placeId: 'custom_search',
          primaryText: query,
          secondaryText: 'Search around current area',
          fullDescription: '$query (Area result)',
        ),
      ];
    }
    return filtered;
  }

  PlaceLocation _getFallbackCoordinates(PlaceSuggestion suggestion) {
    // Deterministic realistic coordinates around New Delhi / NCR for mock previews
    switch (suggestion.placeId) {
      case 'del_cp':
        return PlaceLocation(
          name: suggestion.primaryText,
          latitude: 28.6315,
          longitude: 77.2167,
          placeId: suggestion.placeId,
          secondaryText: suggestion.secondaryText,
        );
      case 'del_hzk':
        return PlaceLocation(
          name: suggestion.primaryText,
          latitude: 28.5534,
          longitude: 77.1942,
          placeId: suggestion.placeId,
          secondaryText: suggestion.secondaryText,
        );
      case 'del_sec29':
        return PlaceLocation(
          name: suggestion.primaryText,
          latitude: 28.4682,
          longitude: 77.0634,
          placeId: suggestion.placeId,
          secondaryText: suggestion.secondaryText,
        );
      case 'del_cyberhub':
        return PlaceLocation(
          name: suggestion.primaryText,
          latitude: 28.4986,
          longitude: 77.0890,
          placeId: suggestion.placeId,
          secondaryText: suggestion.secondaryText,
        );
      case 'del_saket':
        return PlaceLocation(
          name: suggestion.primaryText,
          latitude: 28.5284,
          longitude: 77.2185,
          placeId: suggestion.placeId,
          secondaryText: suggestion.secondaryText,
        );
      case 'del_noida18':
        return PlaceLocation(
          name: suggestion.primaryText,
          latitude: 28.5708,
          longitude: 77.3271,
          placeId: suggestion.placeId,
          secondaryText: suggestion.secondaryText,
        );
      case 'del_aiims':
        return PlaceLocation(
          name: suggestion.primaryText,
          latitude: 28.5672,
          longitude: 77.2100,
          placeId: suggestion.placeId,
          secondaryText: suggestion.secondaryText,
        );
      case 'del_iit':
        return PlaceLocation(
          name: suggestion.primaryText,
          latitude: 28.5450,
          longitude: 77.1926,
          placeId: suggestion.placeId,
          secondaryText: suggestion.secondaryText,
        );
      default:
        // Hash code variation around Delhi coordinates
        final offset = (suggestion.primaryText.hashCode % 100) / 1000.0;
        return PlaceLocation(
          name: suggestion.primaryText,
          latitude: 28.6139 + offset,
          longitude: 77.2090 + offset,
          placeId: suggestion.placeId,
          secondaryText: suggestion.secondaryText,
        );
    }
  }
}
