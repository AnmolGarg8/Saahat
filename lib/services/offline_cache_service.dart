import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Step-by-step navigation instruction for offline directions.
class OfflineRouteStep {
  final String instruction;
  final String distanceText;
  final String iconType; // "depart", "turn_right", "turn_left", "straight", "transit", "arrive"
  final String? safetyNote;

  const OfflineRouteStep({
    required this.instruction,
    required this.distanceText,
    this.iconType = "straight",
    this.safetyNote,
  });

  Map<String, dynamic> toJson() => {
    'instruction': instruction,
    'distanceText': distanceText,
    'iconType': iconType,
    'safetyNote': safetyNote,
  };

  factory OfflineRouteStep.fromJson(Map<String, dynamic> json) => OfflineRouteStep(
    instruction: json['instruction'] as String? ?? '',
    distanceText: json['distanceText'] as String? ?? '',
    iconType: json['iconType'] as String? ?? 'straight',
    safetyNote: json['safetyNote'] as String?,
  );
}

/// Cached route stored locally for offline viewing.
class OfflineCachedRoute {
  final String origin;
  final String destination;
  final String routeTitle;
  final String durationText;
  final String distanceText;
  final double fitScore;
  final String contextTag;
  final List<OfflineRouteStep> steps;
  final DateTime savedAt;

  const OfflineCachedRoute({
    required this.origin,
    required this.destination,
    required this.routeTitle,
    required this.durationText,
    required this.distanceText,
    required this.fitScore,
    required this.contextTag,
    required this.steps,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'origin': origin,
    'destination': destination,
    'routeTitle': routeTitle,
    'durationText': durationText,
    'distanceText': distanceText,
    'fitScore': fitScore,
    'contextTag': contextTag,
    'steps': steps.map((s) => s.toJson()).toList(),
    'savedAt': savedAt.toIso8601String(),
  };

  factory OfflineCachedRoute.fromJson(Map<String, dynamic> json) {
    final rawSteps = (json['steps'] as List<dynamic>?) ?? [];
    return OfflineCachedRoute(
      origin: json['origin'] as String? ?? 'IIT Delhi Main Gate',
      destination: json['destination'] as String? ?? 'Select Citywalk Mall, Saket',
      routeTitle: json['routeTitle'] as String? ?? 'Main Arterial Corridor (Safest)',
      durationText: json['durationText'] as String? ?? '16 min',
      distanceText: json['distanceText'] as String? ?? '4.9 km',
      fitScore: (json['fitScore'] as num?)?.toDouble() ?? 9.4,
      contextTag: json['contextTag'] as String? ?? 'Continuous streetlights & high commercial footfall',
      steps: rawSteps.map((s) => OfflineRouteStep.fromJson(s as Map<String, dynamic>)).toList(),
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Offline emergency help point saved locally.
class OfflineHelpPoint {
  final String name;
  final String category; // 'police', 'hospital', 'pharmacy_247'
  final String address;
  final String distance;
  final String phone;

  const OfflineHelpPoint({
    required this.name,
    required this.category,
    required this.address,
    required this.distance,
    required this.phone,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'address': address,
    'distance': distance,
    'phone': phone,
  };

  factory OfflineHelpPoint.fromJson(Map<String, dynamic> json) => OfflineHelpPoint(
    name: json['name'] as String? ?? '',
    category: json['category'] as String? ?? 'police',
    address: json['address'] as String? ?? '',
    distance: json['distance'] as String? ?? '',
    phone: json['phone'] as String? ?? '112',
  );
}

/// Service managing offline cached routes, help points, and safe check-ins.
class OfflineCacheService {
  static const String _keyLastRoute = 'saahat_offline_last_route';
  static const String _keyHelpPoints = 'saahat_offline_help_points';
  static const String _keyLastCheckIn = 'saahat_offline_last_checkin';

  /// Preloaded default route ensuring offline directions work immediately.
  static final OfflineCachedRoute defaultFallbackRoute = OfflineCachedRoute(
    origin: 'IIT Delhi Main Gate',
    destination: 'Select Citywalk Mall, Saket',
    routeTitle: 'Main Arterial Corridor (Safest)',
    durationText: '16 min',
    distanceText: '4.9 km',
    fitScore: 9.4,
    contextTag: 'Continuous streetlights & high footfall till midnight',
    steps: const [
      OfflineRouteStep(
        instruction: 'Depart IIT Delhi Main Gate onto Outer Ring Road / Gamal Abdel Nasser Marg',
        distanceText: '800 m',
        iconType: 'depart',
        safetyNote: 'Wide footpaths, illuminated university boulevard',
      ),
      OfflineRouteStep(
        instruction: 'Keep right onto Sri Aurobindo Marg heading south',
        distanceText: '1.2 km',
        iconType: 'straight',
        safetyNote: 'High commercial activity, regular public buses running',
      ),
      OfflineRouteStep(
        instruction: 'Pass Hauz Khas Metro Station (Gate 2)',
        distanceText: '1.1 km',
        iconType: 'transit',
        safetyNote: 'Police assistance booth active 24/7 at station entrance',
      ),
      OfflineRouteStep(
        instruction: 'Turn left onto Press Enclave Marg toward Saket District Centre',
        distanceText: '900 m',
        iconType: 'turn_left',
        safetyNote: 'Well-lit central divider with emergency call boxes',
      ),
      OfflineRouteStep(
        instruction: 'Continue past Max Super Speciality Hospital Saket',
        distanceText: '600 m',
        iconType: 'straight',
        safetyNote: '24/7 emergency trauma ward & security guards on duty',
      ),
      OfflineRouteStep(
        instruction: 'Arrive at Select Citywalk Saket (Main Drop Zone)',
        distanceText: '300 m',
        iconType: 'arrive',
        safetyNote: 'Designated brightly lit taxi pickup zone with mall security',
      ),
    ],
    savedAt: DateTime.now(),
  );

  /// Preloaded default help points saved locally.
  static final List<OfflineHelpPoint> defaultHelpPoints = const [
    OfflineHelpPoint(
      name: 'Police Station Malviya Nagar',
      category: 'police',
      address: 'A Block Main Road, Hauz Khas / Malviya Nagar, Delhi - 110017',
      distance: '1.8 km',
      phone: '+91-11-2669-1861',
    ),
    OfflineHelpPoint(
      name: 'Max Super Speciality Hospital (Emergency)',
      category: 'hospital',
      address: '1, 2 Press Enclave Road, Saket District Centre, Delhi - 110017',
      distance: '600 m',
      phone: '+91-11-2651-5050',
    ),
    OfflineHelpPoint(
      name: 'Apollo 24/7 Pharmacy & Chemist',
      category: 'pharmacy_247',
      address: 'Shop 4, Ground Floor, Saket Community Center, Delhi - 110017',
      distance: '450 m',
      phone: '1860-500-0101',
    ),
  ];

  /// Retrieves the last cached route or the fallback offline route.
  static Future<OfflineCachedRoute> getLastCachedRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyLastRoute);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return OfflineCachedRoute.fromJson(map);
      }
    } catch (_) {}
    return defaultFallbackRoute;
  }

  /// Saves a route for offline access.
  static Future<void> saveRouteForOffline(OfflineCachedRoute route) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastRoute, jsonEncode(route.toJson()));
    } catch (_) {}
  }

  /// Retrieves saved nearby offline help points.
  static Future<List<OfflineHelpPoint>> getOfflineHelpPoints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyHelpPoints);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        if (list.isNotEmpty) {
          return list.map((e) => OfflineHelpPoint.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}
    return defaultHelpPoints;
  }

  /// Saves nearby help points to local storage.
  static Future<void> saveHelpPoints(List<OfflineHelpPoint> points) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(points.map((p) => p.toJson()).toList());
      await prefs.setString(_keyHelpPoints, encoded);
    } catch (_) {}
  }

  /// Records an offline check-in.
  static Future<void> recordCheckIn(String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().toIso8601String();
      await prefs.setString(_keyLastCheckIn, '$status|$timestamp');
    } catch (_) {}
  }

  /// Retrieves last recorded check-in string.
  static Future<String?> getLastCheckIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyLastCheckIn);
    } catch (_) {
      return null;
    }
  }
}
