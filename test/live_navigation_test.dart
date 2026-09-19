import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saahat_app/models/place_location.dart';
import 'package:saahat_app/screens/live_navigation_screen.dart';
import 'package:saahat_app/screens/route_results_screen.dart';
import 'package:saahat_app/services/route_scoring_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockFrom = PlaceLocation(
    name: 'Charlie\'s Cafe',
    secondaryText: '1044 N Rengstorff Ave, Mountain View',
    latitude: 37.4138,
    longitude: -122.0970,
  );

  final mockTo = PlaceLocation(
    name: 'Shoreline Amphitheatre',
    secondaryText: 'One Amphitheatre Pkwy, Mountain View',
    latitude: 37.4268,
    longitude: -122.0807,
  );

  final mockBreakdown = RouteScoreBreakdown(
    lightingScore: 9.5,
    footfallScore: 9.0,
    transitScore: 9.2,
    emergencyScore: 9.4,
    directnessScore: 9.0,
    lightingDetail: 'LED streetlights active',
    footfallDetail: 'High footfall',
    transitDetail: 'Near transit hub',
    emergencyDetail: 'Police post 500m',
  );

  final mockRoute = ScoredRoute(
    id: 'route_1',
    title: 'Main Arterial Route',
    viaRoad: 'via Central Expressway',
    fitScore: 9.4,
    contextTag: 'Well-lit commercial corridor with active footfall',
    pros: ['Continuous bright LED streetlighting', 'High pedestrian footfall'],
    cons: ['Moderate vehicle traffic'],
    breakdown: mockBreakdown,
    isBestMatch: true,
    distanceKm: 3.5,
    durationMinutes: 12,
    coordinates: [
      [37.4138, -122.0970],
      [37.4200, -122.0900],
      [37.4268, -122.0807],
    ],
    roadType: 'arterial',
  );

  group('Route Results "Start Journey" Button Tests', () {
    testWidgets('RouteResultsScreen renders prominent Start Journey button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RouteResultsScreen(
            from: mockFrom,
            to: mockTo,
          ),
        ),
      );

      // Wait for initial load
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Check if Start Journey button exists
      final startJourneyFinder = find.widgetWithText(ElevatedButton, 'Start Journey');
      expect(startJourneyFinder, findsAtLeastNWidgets(1));
    });
  });

  group('LiveNavigationScreen Tests', () {
    testWidgets('Renders turn-by-turn banner, ETA panel, and Saarthi voice bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LiveNavigationScreen(
            route: mockRoute,
            from: mockFrom,
            to: mockTo,
            safetyPOIs: const [],
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify turn-by-turn header exists
      expect(find.textContaining('Depart Charlie\'s Cafe'), findsOneWidget);

      // Verify live ETA metrics
      expect(find.text('min'), findsOneWidget);
      expect(find.textContaining('FIT'), findsOneWidget);
      expect(find.text('Share ETA'), findsOneWidget);
      expect(find.text('End Journey'), findsOneWidget);
      expect(find.text('SOS'), findsOneWidget);

      // Verify Saarthi Voice bar
      expect(find.text('Ask AI'), findsOneWidget);
    });

    testWidgets('Tapping Next Turn advances maneuver step', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LiveNavigationScreen(
            route: mockRoute,
            from: mockFrom,
            to: mockTo,
            safetyPOIs: const [],
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Initial step
      expect(find.textContaining('Depart Charlie\'s Cafe'), findsOneWidget);

      // Tap Next Turn button
      final nextTurnBtn = find.byTooltip('Next Turn');
      expect(nextTurnBtn, findsOneWidget);
      await tester.tap(nextTurnBtn);
      await tester.pump();

      // Second step should appear
      expect(find.textContaining('Turn right onto via Central Expressway'), findsOneWidget);
    });
  });
}
