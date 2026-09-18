import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saahat_app/screens/sos_screen.dart';

void main() {
  testWidgets('SOS Emergency Screen renders all emergency components and toggles location', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: SosScreen(),
      ),
    );

    // Initial frame
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify header and emergency banner
    expect(find.text('Emergency Response'), findsOneWidget);
    expect(find.text('EMERGENCY ACTIVATED'), findsOneWidget);

    // Verify Nearest Police Station section
    expect(find.text('NEAREST POLICE STATION'), findsOneWidget);

    // Verify Instant Emergency Call Buttons
    expect(find.text('Instant Emergency Dial'), findsOneWidget);
    expect(find.text('Call Police (112 / 100)'), findsOneWidget);
    expect(find.text('Priya Sharma (Sister)'), findsOneWidget);

    // Verify Live Location Sharing Toggle Card
    expect(find.text('Share My Live Location'), findsOneWidget);
    expect(find.text('Live location sharing active — trusted contacts notified'), findsOneWidget);

    // Verify I'm Safe Now Button
    expect(find.text("I'm Safe Now"), findsOneWidget);

    // Test toggle switch
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);
    await tester.tap(switchFinder);
    await tester.pump();
    expect(find.text('Live location sharing is paused.'), findsOneWidget);

    // Tap I'm Safe Now button to trigger calm exit animation
    await tester.tap(find.text("I'm Safe Now"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Emergency Deactivated'), findsOneWidget);
    expect(find.text("Glad you're safe. Your emergency broadcast & location sharing have ended."), findsOneWidget);

    // Allow delayed pop timer to complete
    await tester.pump(const Duration(milliseconds: 2000));
  });
}
