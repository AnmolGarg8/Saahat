import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saahat_app/main.dart';
import 'package:saahat_app/services/low_signal_controller.dart';
import 'package:saahat_app/services/offline_cache_service.dart';
import 'package:saahat_app/widgets/low_signal_offline_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LowSignalController.instance.resetForTesting(false);
  });

  tearDown(() async {
    await LowSignalController.instance.setLowSignalMode(false);
  });

  group('LowSignalController & OfflineCacheService Tests', () {
    test('Controller toggles low signal mode state properly', () async {
      final controller = LowSignalController.instance;
      controller.resetForTesting(false);
      expect(controller.isLowSignalMode, false);

      await controller.toggleLowSignalMode();
      expect(controller.isLowSignalMode, true);

      await controller.toggleLowSignalMode();
      expect(controller.isLowSignalMode, false);
    });

    test('OfflineCacheService returns robust default fallback route and help points', () async {
      final route = await OfflineCacheService.getLastCachedRoute();
      expect(route.origin, contains('IIT Delhi'));
      expect(route.destination, contains('Select Citywalk'));
      expect(route.steps.length, greaterThanOrEqualTo(5));

      final points = await OfflineCacheService.getOfflineHelpPoints();
      expect(points.length, greaterThanOrEqualTo(3));
      expect(points.any((p) => p.category == 'police'), isTrue);
      expect(points.any((p) => p.category == 'hospital'), isTrue);
      expect(points.any((p) => p.category == 'pharmacy_247'), isTrue);
    });

    test('OfflineCacheService records and retrieves offline check-in logs', () async {
      await OfflineCacheService.recordCheckIn("I'm Safe and Traveling");
      final checkIn = await OfflineCacheService.getLastCheckIn();
      expect(checkIn, isNotNull);
      expect(checkIn, contains("I'm Safe and Traveling"));
    });
  });

  group('LowSignalOfflineView Widget Tests', () {
    testWidgets('Renders all offline cards, directions, help points, and records check-in', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LowSignalOfflineView(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify battery saver notice
      expect(find.textContaining('OLED true dark active'), findsOneWidget);

      // Verify check-in section
      expect(find.text('OFFLINE CHECK-IN'), findsOneWidget);
      expect(find.text("I'M OK"), findsOneWidget);
      expect(find.text("NEED HELP"), findsOneWidget);

      // Verify offline cached route card
      expect(find.text('SAVED FOR OFFLINE USE'), findsOneWidget);
      expect(find.textContaining('IIT Delhi'), findsWidgets);
      expect(find.textContaining('Select Citywalk'), findsWidgets);

      // Verify Step-by-step instructions
      expect(find.textContaining('Step-by-Step Directions'), findsOneWidget);
      expect(find.text('Step 1'), findsOneWidget);

      // Verify Nearby Help Points card
      expect(find.text('NEARBY HELP POINTS'), findsOneWidget);
      expect(find.text('Saved for offline use'), findsOneWidget);
      expect(find.textContaining('Police Station Malviya Nagar'), findsOneWidget);

      // Tap "I'M OK" button and verify feedback
      await tester.tap(find.text("I'M OK"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining("Logged: I'm OK"), findsOneWidget);
    });
  });

  group('Global App Low Signal Mode & Persistent Banner Tests', () {
    testWidgets('Toggling Low Signal Mode switches theme and displays persistent banner across app', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const SaahatApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Initially, persistent banner is NOT shown
      expect(find.text('LOW SIGNAL & BATTERY MODE: ON'), findsNothing);

      // Toggle Low Signal Mode ON via controller
      await LowSignalController.instance.setLowSignalMode(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Persistent banner is now visible!
      expect(find.text('LOW SIGNAL & BATTERY MODE: ON'), findsOneWidget);
      expect(find.text('Turn Off'), findsOneWidget);

      // Tap "Turn Off" on the persistent banner
      await tester.tap(find.text('Turn Off'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Banner is removed
      expect(find.text('LOW SIGNAL & BATTERY MODE: ON'), findsNothing);
      expect(LowSignalController.instance.isLowSignalMode, false);
    });
  });
}
