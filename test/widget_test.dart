import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saahat_app/main.dart';
import 'package:saahat_app/screens/profile_screen.dart';
import 'package:saahat_app/screens/sos_screen.dart';

void main() {
  testWidgets('Saahat Home screen and Plan My Journey navigation test', (WidgetTester tester) async {
    await tester.pumpWidget(const SaahatApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    // Verify branding and hero section on Home screen
    expect(find.text('Saahat'), findsOneWidget);
    expect(find.text('Your journey. Your choice. Your confidence.'), findsOneWidget);
    expect(find.text('Go beyond the fastest route.'), findsOneWidget);
    expect(find.textContaining('Saahat helps you choose a journey that fits the moment'), findsOneWidget);

    // Verify 3 feature highlight cards
    expect(find.text('Real conditions, not just distance'), findsOneWidget);
    expect(find.text('No live tracking, ever'), findsOneWidget);
    expect(find.text('We describe, we never judge an area'), findsOneWidget);

    // Verify "Plan My Journey" button navigates to Find Route tab
    expect(find.text('Plan My Journey'), findsOneWidget);
    await tester.tap(find.text('Plan My Journey'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Find Safe Route'), findsOneWidget);

    // Switch back to Home tab
    await tester.tap(find.text('Home'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify avatar icon opens ProfileScreen
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ProfileScreen), findsOneWidget);

    // Go back from ProfileScreen
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify SOS button opens SosScreen
    expect(find.text('SOS'), findsOneWidget);
    await tester.tap(find.text('SOS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SosScreen), findsOneWidget);
  });
}
