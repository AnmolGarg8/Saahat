import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saahat_app/models/trusted_contact.dart';
import 'package:saahat_app/screens/share_eta_screen.dart';
import 'package:saahat_app/services/eta_sharing_service.dart';
import 'package:saahat_app/widgets/arrived_safely_dialog.dart';

void main() {
  group('TrustedContact & EtaSharingService Tests', () {
    test('TrustedContact contains default contacts with Indian phone formats', () {
      final contacts = TrustedContact.defaultContacts;
      expect(contacts.length, 4);

      // Verify Mom/Anjali
      final mom = contacts.firstWhere((c) => c.relation == 'Mom');
      expect(mom.name, 'Anjali');
      expect(mom.phone, '+91 98765 43210');
      expect(mom.initials, 'A');

      // Verify Sara/Roommate
      final roommate = contacts.firstWhere((c) => c.relation == 'Roommate');
      expect(roommate.name, 'Sara');
      expect(roommate.phone, '+91 98123 45678');

      // Verify Priya/Sister
      final sister = contacts.firstWhere((c) => c.relation == 'Sister');
      expect(sister.name, 'Priya');
      expect(sister.phone, '+91 98234 56789');

      // Verify Elena/Colleague
      final colleague = contacts.firstWhere((c) => c.relation == 'Colleague');
      expect(colleague.name, 'Elena');
      expect(colleague.phone, '+91 98345 67890');
    });

    test('EtaSharingService generates exact message format required by prompt', () {
      final message = EtaSharingService.formatEtaMessage(
        routeName: 'Main Arterial Route',
        durationMinutes: 25,
        formattedArrivalTime: '11:45 PM',
      );

      expect(
        message,
        "I'm heading home via Main Arterial Route (25 mins), expected arrival by 11:45 PM. Powered by Saahat.",
      );
    });

    test('EtaSharingService tracks active trip status and arrival', () {
      final service = EtaSharingService.instance;
      final contact = TrustedContact.defaultContacts.first;

      service.startTrip(
        contact: contact,
        routeName: 'Main Arterial Route',
        durationMinutes: 25,
        expectedArrival: const TimeOfDay(hour: 23, minute: 45),
      );

      expect(service.isTripActive, isTrue);
      expect(service.activeContact?.name, 'Anjali');

      service.markArrivedSafely();
      expect(service.isTripActive, isFalse);
    });
  });

  group('ShareEtaScreen Widget Tests', () {
    testWidgets('Renders contacts, route selector, arrival time, preview box and buttons', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: ShareEtaScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check header
      expect(find.text('Share ETA'), findsOneWidget);
      expect(find.text('One-time updates • Zero continuous tracking'), findsOneWidget);

      // Check default contacts rendered
      expect(find.text('Anjali'), findsOneWidget);
      expect(find.text('Mom'), findsOneWidget);
      expect(find.text('+91 98765 43210'), findsOneWidget);

      expect(find.text('Sara'), findsOneWidget);
      expect(find.text('Roommate'), findsOneWidget);

      expect(find.text('Priya'), findsOneWidget);
      expect(find.text('Sister'), findsOneWidget);

      expect(find.text('Elena'), findsOneWidget);
      expect(find.text('Colleague'), findsOneWidget);

      // Check duration chips
      expect(find.text('+15 min'), findsOneWidget);
      expect(find.text('+25 min'), findsOneWidget);
      expect(find.text('+40 min'), findsOneWidget);
      expect(find.text('+60 min'), findsOneWidget);

      // Check SMS Preview section
      expect(find.text('SMS PREVIEW'), findsOneWidget);
      expect(find.textContaining('Powered by Saahat.'), findsOneWidget);

      // Check action buttons
      expect(find.text('Share ETA with Anjali'), findsOneWidget);
      expect(find.text("I've Arrived Safely"), findsOneWidget);
    });

    testWidgets('Selecting another contact updates active selection and button label', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: ShareEtaScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Sara / Roommate
      await tester.tap(find.text('Sara'));
      await tester.pumpAndSettle();

      // Button updates to Sara
      expect(find.text('Share ETA with Sara'), findsOneWidget);
    });

    testWidgets('Tapping "I\'ve Arrived Safely" opens ArrivedSafelyDialog with completion animation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: ShareEtaScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to reveal buttons
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      final arrivedFinder = find.text("I've Arrived Safely").first;
      expect(arrivedFinder, findsOneWidget);

      // Tap I've Arrived Safely
      await tester.tap(arrivedFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ArrivedSafelyDialog), findsOneWidget);
      expect(find.text("You've Arrived Safely!"), findsOneWidget);
      expect(find.text('Done • Back to Trip'), findsOneWidget);

      // Tap Done
      await tester.tap(find.text('Done • Back to Trip'));
      await tester.pumpAndSettle();

      expect(find.byType(ArrivedSafelyDialog), findsNothing);
    });
  });
}
