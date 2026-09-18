import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saahat_app/main.dart';
import 'package:saahat_app/screens/route_results_screen.dart';

void main() {
  testWidgets('Find Route screen search, autocomplete and navigation test', (WidgetTester tester) async {
    await tester.pumpWidget(const SaahatApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    // Tap "Find Route" tab in bottom navigation
    await tester.tap(find.text('Find Route'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify search fields and buttons exist
    expect(find.text('Find Safe Route'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('Leaving now'), findsOneWidget);
    expect(find.text('Set time'), findsOneWidget);
    expect(find.text('Search Journey'), findsOneWidget);

    // Enter text in "From" field
    final fromField = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == 'Enter pickup or starting place...',
    );
    expect(fromField, findsOneWidget);
    await tester.enterText(fromField, 'Connaught');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Suggestions should show 'Connaught Place'
    expect(find.text('Connaught Place'), findsOneWidget);
    await tester.tap(find.text('Connaught Place'));
    await tester.pump();

    // Enter text in "To" field
    final toField = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == 'Enter destination or landmark...',
    );
    expect(toField, findsOneWidget);
    await tester.enterText(toField, 'Hauz');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Suggestions should show 'Hauz Khas Village'
    expect(find.text('Hauz Khas Village'), findsOneWidget);
    await tester.tap(find.text('Hauz Khas Village'));
    await tester.pump();

    // Tap "Search Journey" button
    await tester.tap(find.text('Search Journey'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify navigation to RouteResultsScreen with selected places
    expect(find.byType(RouteResultsScreen), findsOneWidget);
    expect(
      find.descendant(of: find.byType(RouteResultsScreen), matching: find.text('Connaught Place')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(RouteResultsScreen), matching: find.text('Hauz Khas Village')),
      findsOneWidget,
    );
    expect(find.text('Route Results'), findsOneWidget);
  });
}
