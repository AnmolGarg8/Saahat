import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/place_location.dart';

class RouteStep {
  final String instruction;
  final double distanceMeters;
  final double timeSeconds;

  const RouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.timeSeconds,
  });
}

class CalculatedRoute {
  final double distanceKm;
  final int durationMinutes;
  final List<List<double>> coordinates; // [[lat, lon], ...]
  final List<RouteStep> steps;

  const CalculatedRoute({
    required this.distanceKm,
    required this.durationMinutes,
    required this.coordinates,
    required this.steps,
  });
}

class RoutingService {
  final http.Client _client;

  RoutingService({http.Client? client}) : _client = client ?? http.Client();

  /// Calculates a real driving/transit route using Geoapify Routing API.
  Future<CalculatedRoute?> calculateRoute({
    required PlaceLocation from,
    required PlaceLocation to,
    String mode = 'drive', // 'drive', 'walk', 'bicycle', 'transit'
  }) async {
    try {
      final url = Uri.parse(
        'https://api.geoapify.com/v1/routing'
        '?waypoints=${from.latitude},${from.longitude}|${to.latitude},${to.longitude}'
        '&mode=$mode'
        '&apiKey=${ApiConfig.routingApiKey}',
      );

      final response = await _client.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>?;
        if (features != null && features.isNotEmpty) {
          final feature = features.first as Map<String, dynamic>;
          final properties = feature['properties'] as Map<String, dynamic>? ?? {};
          final geometry = feature['geometry'] as Map<String, dynamic>? ?? {};

          final distanceMeters = (properties['distance'] as num?)?.toDouble() ?? 0.0;
          final timeSeconds = (properties['time'] as num?)?.toDouble() ?? 0.0;

          // GeoJSON coordinates are [lon, lat] - convert to [lat, lon]
          final rawCoords = (geometry['coordinates'] as List<dynamic>?) ?? [];
          final List<List<double>> polyline = [];
          for (final point in rawCoords) {
            if (point is List && point.length >= 2) {
              polyline.add([(point[1] as num).toDouble(), (point[0] as num).toDouble()]);
            }
          }

          // Parse navigation steps
          final List<RouteStep> steps = [];
          final legs = properties['legs'] as List<dynamic>?;
          if (legs != null && legs.isNotEmpty) {
            final legSteps = legs.first['steps'] as List<dynamic>? ?? [];
            for (final step in legSteps) {
              final instruction = step['instruction']?['text'] as String? ?? '';
              final d = (step['distance'] as num?)?.toDouble() ?? 0.0;
              final t = (step['time'] as num?)?.toDouble() ?? 0.0;
              if (instruction.isNotEmpty) {
                steps.add(RouteStep(
                  instruction: instruction,
                  distanceMeters: d,
                  timeSeconds: t,
                ));
              }
            }
          }

          return CalculatedRoute(
            distanceKm: distanceMeters / 1000.0,
            durationMinutes: (timeSeconds / 60.0).round(),
            coordinates: polyline,
            steps: steps,
          );
        }
      }
    } catch (_) {}
    return null;
  }
}
