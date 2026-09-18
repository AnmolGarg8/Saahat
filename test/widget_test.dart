import 'package:flutter_test/flutter_test.dart';
import 'package:saahat_app/main.dart';
import 'package:saahat_app/screens/sos_screen.dart';

void main() {
  testWidgets('Saahat core app structure smoke and navigation test', (WidgetTester tester) async {
    await tester.pumpWidget(const SaahatApp());
    await tester.pump();

    // Verify branding on Home screen
    expect(find.text('Saahat'), findsOneWidget);
    expect(find.text('Har Safar Mein Raahat'), findsOneWidget);

    // Verify all 5 navigation tabs exist
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Find Route'), findsOneWidget);
    expect(find.text('Share ETA'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);

    // Verify SOS button exists
    expect(find.text('SOS'), findsOneWidget);

    // Switch to Find Route tab
    await tester.tap(find.text('Find Route'));
    await tester.pump();
    expect(find.text('Find Safe Route'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget);

    // Switch to Share ETA tab
    await tester.tap(find.text('Share ETA'));
    await tester.pump();
    expect(find.text('Share Your Trip & ETA'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget);

    // Switch to Notes tab
    await tester.tap(find.text('Notes'));
    await tester.pump();
    expect(find.text('Community Notes'), findsWidgets);
    expect(find.text('SOS'), findsOneWidget);

    // Switch to About tab
    await tester.tap(find.text('About'));
    await tester.pump();
    expect(find.text('About Saahat'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget);

    // Tap SOS button and advance past page route transition
    await tester.tap(find.text('SOS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SosScreen), findsOneWidget);
    expect(find.text('Emergency SOS'), findsOneWidget);
  });
}
