import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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
  final String? mapImagePath;
  final String? mapImageBase64;
  final int? storageSizeBytes;

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
    this.mapImagePath,
    this.mapImageBase64,
    this.storageSizeBytes,
  });

  String get formattedStorageSize {
    final bytes = storageSizeBytes ?? 43500;
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).round()} KB';
  }

  OfflineCachedRoute copyWith({
    String? origin,
    String? destination,
    String? routeTitle,
    String? durationText,
    String? distanceText,
    double? fitScore,
    String? contextTag,
    List<OfflineRouteStep>? steps,
    DateTime? savedAt,
    String? mapImagePath,
    String? mapImageBase64,
    int? storageSizeBytes,
  }) {
    return OfflineCachedRoute(
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      routeTitle: routeTitle ?? this.routeTitle,
      durationText: durationText ?? this.durationText,
      distanceText: distanceText ?? this.distanceText,
      fitScore: fitScore ?? this.fitScore,
      contextTag: contextTag ?? this.contextTag,
      steps: steps ?? this.steps,
      savedAt: savedAt ?? this.savedAt,
      mapImagePath: mapImagePath ?? this.mapImagePath,
      mapImageBase64: mapImageBase64 ?? this.mapImageBase64,
      storageSizeBytes: storageSizeBytes ?? this.storageSizeBytes,
    );
  }

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
    'mapImagePath': mapImagePath,
    'mapImageBase64': mapImageBase64,
    'storageSizeBytes': storageSizeBytes,
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
      mapImagePath: json['mapImagePath'] as String?,
      mapImageBase64: json['mapImageBase64'] as String?,
      storageSizeBytes: json['storageSizeBytes'] as int?,
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
    storageSizeBytes: 44200,
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

  static const String _mapSnapshotFilename = 'offline_route_map_snapshot.png';

  /// Gets the local file path where the static route map snapshot is stored.
  static Future<String> getOfflineMapFilePath() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return '${dir.path}/$_mapSnapshotFilename';
    } catch (_) {
      return '';
    }
  }

  /// Saves static map snapshot PNG bytes to local file storage.
  static Future<String?> saveMapSnapshotFile(Uint8List bytes) async {
    try {
      final filePath = await getOfflineMapFilePath();
      if (filePath.isNotEmpty) {
        final file = File(filePath);
        await file.writeAsBytes(bytes, flush: true);
        return filePath;
      }
    } catch (_) {}
    return null;
  }

  /// Retrieves cached map snapshot bytes (checking local file first, then base64).
  static Future<Uint8List?> getMapSnapshotBytes([OfflineCachedRoute? route]) async {
    // 1. Try reading from local file path
    try {
      final currentRoute = route ?? await getLastCachedRoute();
      if (currentRoute.mapImagePath != null && currentRoute.mapImagePath!.isNotEmpty) {
        final file = File(currentRoute.mapImagePath!);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          if (bytes.isNotEmpty) return bytes;
        }
      }
      final defaultPath = await getOfflineMapFilePath();
      if (defaultPath.isNotEmpty) {
        final defaultFile = File(defaultPath);
        if (await defaultFile.exists()) {
          final bytes = await defaultFile.readAsBytes();
          if (bytes.isNotEmpty) return bytes;
        }
      }
    } catch (_) {}

    // 2. Try decoding from base64 string
    try {
      final currentRoute = route ?? await getLastCachedRoute();
      if (currentRoute.mapImageBase64 != null && currentRoute.mapImageBase64!.isNotEmpty) {
        return base64Decode(currentRoute.mapImageBase64!);
      }
    } catch (_) {}

    // 3. Generate a crisp canvas fallback snapshot if none exists
    try {
      return await generateCanvasRouteSnapshot(
        origin: route?.origin ?? 'IIT Delhi Main Gate',
        destination: route?.destination ?? 'Select Citywalk Mall, Saket',
        viaRoad: route?.routeTitle ?? 'Main Arterial Corridor',
        distanceText: route?.distanceText ?? '4.9 km',
        durationText: route?.durationText ?? '16 min',
      );
    } catch (_) {
      return null;
    }
  }

  /// Generates a high-contrast vector route map snapshot image (PNG bytes).
  static Future<Uint8List> generateCanvasRouteSnapshot({
    required String origin,
    required String destination,
    required String viaRoad,
    required String distanceText,
    required String durationText,
    double width = 640,
    double height = 340,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    // Dark map background
    final bgPaint = Paint()..color = const Color(0xFF13131C);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    // Street grid simulation (background roads)
    final gridPaint = Paint()
      ..color = const Color(0xFF222232)
      ..strokeWidth = 2.0;

    for (double x = 40; x < width; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }
    for (double y = 30; y < height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // Secondary connecting road
    final secondaryRoadPaint = Paint()
      ..color = const Color(0xFF33334A)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final secondaryPath = Path()
      ..moveTo(40, height * 0.7)
      ..quadraticBezierTo(width * 0.4, height * 0.85, width - 40, height * 0.45);
    canvas.drawPath(secondaryPath, secondaryRoadPaint);

    // Main route path outer glow
    final glowPaint = Paint()
      ..color = const Color(0xFF6C2BD9).withValues(alpha: 0.4)
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final routePath = Path()
      ..moveTo(60, height * 0.35)
      ..cubicTo(
        width * 0.3, height * 0.25,
        width * 0.45, height * 0.75,
        width * 0.75, height * 0.65,
      )
      ..lineTo(width - 70, height * 0.35);

    canvas.drawPath(routePath, glowPaint);

    // Main route path solid line
    final routeLinePaint = Paint()
      ..color = const Color(0xFF8B5CF6)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(routePath, routeLinePaint);

    // Inner bright core
    final routeCorePaint = Paint()
      ..color = const Color(0xFFE9D5FF)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(routePath, routeCorePaint);

    // Origin Pin (Point A - Teal/Green)
    final originCenter = Offset(60, height * 0.35);
    final originHalo = Paint()..color = const Color(0xFF00C2A8).withValues(alpha: 0.3);
    canvas.drawCircle(originCenter, 16, originHalo);
    final originPaint = Paint()..color = const Color(0xFF00C2A8);
    canvas.drawCircle(originCenter, 10, originPaint);
    final originCore = Paint()..color = Colors.white;
    canvas.drawCircle(originCenter, 4, originCore);

    // Destination Pin (Point B - Magenta/Pink)
    final destCenter = Offset(width - 70, height * 0.35);
    final destHalo = Paint()..color = const Color(0xFFFF4D8D).withValues(alpha: 0.35);
    canvas.drawCircle(destCenter, 18, destHalo);
    final destPaint = Paint()..color = const Color(0xFFFF4D8D);
    canvas.drawCircle(destCenter, 11, destPaint);
    final destCore = Paint()..color = Colors.white;
    canvas.drawCircle(destCenter, 4.5, destCore);

    // Intermediate Safety POI Badges along corridor
    // Police Station POI
    final policeCenter = Offset(width * 0.36, height * 0.44);
    canvas.drawCircle(policeCenter, 9, Paint()..color = const Color(0xFF2563EB));
    canvas.drawCircle(policeCenter, 3, Paint()..color = Colors.white);

    // Hospital POI
    final hospitalCenter = Offset(width * 0.65, height * 0.68);
    canvas.drawCircle(hospitalCenter, 9, Paint()..color = const Color(0xFFDC2626));
    canvas.drawCircle(hospitalCenter, 3, Paint()..color = Colors.white);

    // Top Header Overlay Badge on Map Snapshot
    final badgeBg = Paint()..color = const Color(0xDD000000);
    final badgeRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(14, 14, 210, 32),
      const Radius.circular(8),
    );
    canvas.drawRRect(badgeRRect, badgeBg);

    final borderPaint = Paint()
      ..color = const Color(0xFFFFD600)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(badgeRRect, borderPaint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'OFFLINE MAP SNAPSHOT',
        style: TextStyle(
          color: Color(0xFFFFD600),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(26, 22));

    // Bottom Stats Overlay Badge
    final statsBg = Paint()..color = const Color(0xDD111119);
    final statsRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(width - 170, height - 44, 156, 30),
      const Radius.circular(6),
    );
    canvas.drawRRect(statsRRect, statsBg);

    final statsPainter = TextPainter(
      text: TextSpan(
        text: '$durationText • $distanceText',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    statsPainter.layout();
    statsPainter.paint(canvas, Offset(width - 156, height - 37));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

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

  /// Saves a route for offline access, along with the static map snapshot.
  /// Returns the estimated total storage size in bytes.
  static Future<int> saveRouteForOffline(
    OfflineCachedRoute route, {
    Uint8List? mapImageBytes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      Uint8List? snapshotBytes = mapImageBytes;
      if (snapshotBytes == null || snapshotBytes.isEmpty) {
        snapshotBytes = await generateCanvasRouteSnapshot(
          origin: route.origin,
          destination: route.destination,
          viaRoad: route.routeTitle,
          distanceText: route.distanceText,
          durationText: route.durationText,
        );
      }

      // Save map snapshot to local device file storage
      final localFilePath = await saveMapSnapshotFile(snapshotBytes);
      final base64String = base64Encode(snapshotBytes);

      // Total estimated storage size in bytes: JSON text length + image byte length
      final textBytesEstimate = utf8.encode(jsonEncode(route.toJson())).length;
      final totalSizeBytes = textBytesEstimate + snapshotBytes.length;

      final updatedRoute = route.copyWith(
        mapImagePath: localFilePath,
        mapImageBase64: base64String,
        storageSizeBytes: totalSizeBytes,
        savedAt: DateTime.now(),
      );

      await prefs.setString(_keyLastRoute, jsonEncode(updatedRoute.toJson()));
      return totalSizeBytes;
    } catch (_) {
      return 42000;
    }
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
