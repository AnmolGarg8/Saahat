import 'package:flutter/material.dart';

/// Time of day classification for journey evaluation.
enum TimeOfDayPeriod {
  day('Day (6 AM – 6 PM)', 'Day'),
  evening('Evening (6 PM – 10 PM)', 'Evening'),
  night('Night (10 PM – 6 AM)', 'Night');

  final String label;
  final String shortName;
  const TimeOfDayPeriod(this.label, this.shortName);
}

/// Detailed sub-scores explaining the "Why this score?" breakdown.
class RouteScoreBreakdown {
  final double lightingScore;
  final double footfallScore;
  final double transitScore;
  final double emergencyScore;
  final double directnessScore;
  final String lightingDetail;
  final String footfallDetail;
  final String transitDetail;
  final String emergencyDetail;

  const RouteScoreBreakdown({
    required this.lightingScore,
    required this.footfallScore,
    required this.transitScore,
    required this.emergencyScore,
    required this.directnessScore,
    required this.lightingDetail,
    required this.footfallDetail,
    required this.transitDetail,
    required this.emergencyDetail,
  });
}

/// Scored route representation containing Journey Fit score, context tags, and route geometry.
class ScoredRoute {
  final String id;
  final String title;
  final String viaRoad;
  final double fitScore;
  final String contextTag;
  final List<String> pros;
  final List<String> cons;
  final RouteScoreBreakdown breakdown;
  final bool isBestMatch;
  final double distanceKm;
  final int durationMinutes;
  final List<List<double>> coordinates; // [[lat, lon], ...]
  final String roadType; // 'arterial', 'transit_corridor', 'direct_bypass'

  const ScoredRoute({
    required this.id,
    required this.title,
    required this.viaRoad,
    required this.fitScore,
    required this.contextTag,
    required this.pros,
    required this.cons,
    required this.breakdown,
    required this.isBestMatch,
    required this.distanceKm,
    required this.durationMinutes,
    required this.coordinates,
    required this.roadType,
  });
}

/// Core scoring engine for Saahat.
///
/// NOTE: Currently uses an interpretable, weighted rule-based heuristic function
/// evaluating lighting, footfall, transit access, emergency service proximity,
/// and time-of-day. This class is designed as a standalone service so that the scoring
/// formula can seamlessly be swapped with a trained machine-learning model in future.
class RouteScoringService {
  /// Resolves the relevant time period given the selected departure time.
  static TimeOfDayPeriod resolveTimePeriod(TimeOfDay? departureTime, bool isLeavingNow) {
    int hour;
    if (isLeavingNow || departureTime == null) {
      hour = DateTime.now().hour;
    } else {
      hour = departureTime.hour;
    }

    if (hour >= 6 && hour < 18) {
      return TimeOfDayPeriod.day;
    } else if (hour >= 18 && hour < 22) {
      return TimeOfDayPeriod.evening;
    } else {
      return TimeOfDayPeriod.night;
    }
  }

  /// Evaluates and scores a route profile under current/selected journey conditions.
  static ScoredRoute scoreRouteProfile({
    required String id,
    required String title,
    required String viaRoad,
    required String roadType,
    required double baseDistanceKm,
    required int baseDurationMinutes,
    required List<List<double>> coordinates,
    required TimeOfDayPeriod timePeriod,
    required int policeCountNearby,
    required int hospitalCountNearby,
    required int transitCountNearby,
    bool isBestMatch = false,
  }) {
    // 1. Raw component scores (0.0 to 10.0 scale)
    double lighting;
    double footfall;
    double transit;
    double emergency;
    double directness;

    String lightingDesc;
    String footfallDesc;
    String transitDesc;
    String emergencyDesc;

    switch (roadType) {
      case 'arterial':
        lighting = timePeriod == TimeOfDayPeriod.night ? 9.2 : 9.5;
        footfall = timePeriod == TimeOfDayPeriod.night ? 7.8 : 9.3;
        transit = 9.1;
        emergency = (8.5 + (policeCountNearby * 0.4)).clamp(0.0, 9.8);
        directness = 8.8;

        lightingDesc = 'Broad avenue with continuous high-mast LED coverage.';
        footfallDesc = 'Vibrant commercial storefronts with heavy pedestrian presence.';
        transitDesc = 'Connected to frequent bus routes & arterial stops.';
        emergencyDesc = 'Within 500m of active police patrol & hospital network.';
        break;

      case 'transit_corridor':
        lighting = timePeriod == TimeOfDayPeriod.night ? 8.8 : 9.2;
        footfall = timePeriod == TimeOfDayPeriod.night ? 8.0 : 9.5;
        transit = 9.8;
        emergency = (8.2 + (policeCountNearby * 0.3)).clamp(0.0, 9.6);
        directness = 8.4;

        lightingDesc = 'Well-lit metro station viaducts and lit boarding areas.';
        footfallDesc = 'Steady commuter foot traffic around station entries.';
        transitDesc = 'Direct metro line alignment with sheltered pedestrian access.';
        emergencyDesc = 'Station security checkpoints and visible public assistance booths.';
        break;

      case 'direct_bypass':
      default:
        lighting = timePeriod == TimeOfDayPeriod.night ? 7.0 : 8.2;
        footfall = timePeriod == TimeOfDayPeriod.night ? 6.2 : 8.0;
        transit = 7.5;
        emergency = (7.5 + (policeCountNearby * 0.2)).clamp(0.0, 8.8);
        directness = 9.6;

        lightingDesc = 'Standard municipal streetlamps with intermittent tree canopy shade.';
        footfallDesc = 'Moderate residential traffic; quieter after market hours.';
        transitDesc = 'Local auto-rickshaw stands and feeder bus stops.';
        emergencyDesc = 'Proximity to community dispensary and local beat constable.';
        break;
    }

    // 2. Time-of-day weighted calculation
    // Future ML: Replace with model.predict([lighting, footfall, transit, emergency, directness, timePeriodIndex])
    double wLighting;
    double wFootfall;
    double wTransit;
    double wEmergency;
    double wDirectness;

    switch (timePeriod) {
      case TimeOfDayPeriod.day:
        wLighting = 0.15;
        wFootfall = 0.25;
        wTransit = 0.25;
        wEmergency = 0.15;
        wDirectness = 0.20;
        break;

      case TimeOfDayPeriod.evening:
        wLighting = 0.30;
        wFootfall = 0.30;
        wTransit = 0.20;
        wEmergency = 0.15;
        wDirectness = 0.05;
        break;

      case TimeOfDayPeriod.night:
        wLighting = 0.35;
        wFootfall = 0.25;
        wEmergency = 0.25;
        wTransit = 0.10;
        wDirectness = 0.05;
        break;
    }

    final calculatedScore = (lighting * wLighting) +
        (footfall * wFootfall) +
        (transit * wTransit) +
        (emergency * wEmergency) +
        (directness * wDirectness);

    final roundedScore = (calculatedScore * 10).round() / 10.0;

    // 3. Contextual tags and Pros / Cons
    String contextTag;
    List<String> pros = [];
    List<String> cons = [];

    if (roadType == 'arterial') {
      contextTag = timePeriod == TimeOfDayPeriod.night
          ? 'Well-lit arterial route, staffed police booths'
          : 'Well-lit & busy commercial corridor till 11 PM';
      pros = [
        'Continuous high-mast LED lighting along full stretch',
        'Visible police checkpoints and high public visibility',
        'Active storefronts and open commercial establishments',
      ];
      cons = [
        'Slightly higher vehicular traffic delay (+3-4 min)',
      ];
    } else if (roadType == 'transit_corridor') {
      contextTag = 'Active metro corridor with steady commuter flow';
      pros = [
        'Station security guards and continuous public footfall',
        'Direct multi-modal transit access (Metro + Bus)',
        'Sheltered pedestrian crosswalks and wide walkways',
      ];
      cons = [
        'Busy pedestrian choke points near station gates',
        'Additional 250m walking distance to final destination',
      ];
    } else {
      contextTag = timePeriod == TimeOfDayPeriod.night
          ? 'Shortest route, recommended before 9 PM'
          : 'Fastest direct connection, minimal traffic';
      pros = [
        'Shortest distance and fastest travel time',
        'Less crowded and uninterrupted road flow',
      ];
      cons = [
        timePeriod == TimeOfDayPeriod.night
            ? 'Dimmer secondary street lighting past 9:30 PM'
            : 'Fewer public transit stops along this section',
        'Lower commercial footfall after hours',
      ];
    }

    return ScoredRoute(
      id: id,
      title: title,
      viaRoad: viaRoad,
      fitScore: roundedScore,
      contextTag: contextTag,
      pros: pros,
      cons: cons,
      breakdown: RouteScoreBreakdown(
        lightingScore: lighting,
        footfallScore: footfall,
        transitScore: transit,
        emergencyScore: emergency,
        directnessScore: directness,
        lightingDetail: lightingDesc,
        footfallDetail: footfallDesc,
        transitDetail: transitDesc,
        emergencyDetail: emergencyDesc,
      ),
      isBestMatch: isBestMatch,
      distanceKm: baseDistanceKm,
      durationMinutes: baseDurationMinutes,
      coordinates: coordinates,
      roadType: roadType,
    );
  }
}
