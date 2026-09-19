import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saahat_app/models/community_note.dart';
import 'package:saahat_app/screens/community_notes_screen.dart';
import 'package:saahat_app/services/community_notes_service.dart';
import 'package:saahat_app/services/low_signal_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    LowSignalController.instance.resetForTesting(false);
    CommunityNotesService.instance.resetForTesting(null);
  });

  group('CommunityNote Model Tests', () {
    test('timeAgo calculates relative descriptions correctly', () {
      final now = DateTime.now();
      final justNow = CommunityNote(
        id: '1',
        authorInitial: 'A',
        authorHandle: 'Traveler #1',
        categoryId: 'streetlights',
        locationTag: 'Test Loc',
        text: 'Test note',
        timestamp: now.subtract(const Duration(seconds: 30)),
      );
      expect(justNow.timeAgo, equals('Just now'));

      final minsAgo = CommunityNote(
        id: '2',
        authorInitial: 'B',
        authorHandle: 'Traveler #2',
        categoryId: 'footfall',
        locationTag: 'Test Loc',
        text: 'Test note',
        timestamp: now.subtract(const Duration(minutes: 15)),
      );
      expect(minsAgo.timeAgo, equals('15m ago'));

      final hoursAgo = CommunityNote(
        id: '3',
        authorInitial: 'C',
        authorHandle: 'Traveler #3',
        categoryId: 'transit',
        locationTag: 'Test Loc',
        text: 'Test note',
        timestamp: now.subtract(const Duration(hours: 3)),
      );
      expect(hoursAgo.timeAgo, equals('3h ago'));
    });

    test('toJson and fromJson preserves all fields', () {
      final note = CommunityNote(
        id: 'test-123',
        authorInitial: 'K',
        authorHandle: 'Traveler #999',
        categoryId: 'transit',
        locationTag: 'Saket Metro Gate 2',
        text: 'Brightly lit area with security guard.',
        imagePath: '/mock/path/image.jpg',
        isVerified: true,
        timestamp: DateTime(2026, 9, 19, 8, 0),
      );

      final json = note.toJson();
      final recovered = CommunityNote.fromJson(json);

      expect(recovered.id, equals('test-123'));
      expect(recovered.authorInitial, equals('K'));
      expect(recovered.authorHandle, equals('Traveler #999'));
      expect(recovered.category, equals(NoteCategory.transit));
      expect(recovered.locationTag, equals('Saket Metro Gate 2'));
      expect(recovered.text, equals('Brightly lit area with security guard.'));
      expect(recovered.imagePath, equals('/mock/path/image.jpg'));
      expect(recovered.isVerified, isTrue);
    });
  });

  group('CommunityNotesService Tests', () {
    test('returns default seed notes when storage is empty', () async {
      final notes = await CommunityNotesService.instance.getNotes();
      expect(notes, isNotEmpty);
      expect(notes.length, greaterThanOrEqualTo(4));
    });

    test('filters notes by category correctly', () async {
      final streetlightsNotes = await CommunityNotesService.instance.getNotes(
        category: NoteCategory.streetlights,
      );
      expect(streetlightsNotes, isNotEmpty);
      for (final n in streetlightsNotes) {
        expect(n.categoryId, equals('streetlights'));
      }

      final footfallNotes = await CommunityNotesService.instance.getNotes(
        category: NoteCategory.footfall,
      );
      expect(footfallNotes, isNotEmpty);
      for (final n in footfallNotes) {
        expect(n.categoryId, equals('footfall'));
      }
    });

    test('addNote prepends note to feed and persists to storage', () async {
      final newNote = CommunityNote(
        id: 'user-new-note',
        authorInitial: 'V',
        authorHandle: 'Traveler #777',
        categoryId: 'streetlights',
        locationTag: 'Cyber City Footbridge',
        text: 'All new LED lights installed and working.',
        isVerified: false,
        timestamp: DateTime.now(),
      );

      await CommunityNotesService.instance.addNote(newNote);
      final notes = await CommunityNotesService.instance.getNotes();

      expect(notes.first.id, equals('user-new-note'));
      expect(notes.first.text, equals('All new LED lights installed and working.'));
    });
  });

  group('CommunityNotesScreen Widget Tests', () {
    testWidgets('renders category filter chips and note cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CommunityNotesScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and action buttons
      expect(find.text('Community Notes'), findsOneWidget);
      expect(find.text('Add Note'), findsOneWidget);

      // Check filter categories
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Streetlights'), findsWidgets);
      expect(find.text('Footfall'), findsWidgets);
      expect(find.text('Transit & Stations'), findsWidgets);
      expect(find.text('General'), findsWidgets);

      // Check verification badge
      expect(find.text('Community Verified'), findsWidgets);

      // Tap Footfall category filter
      await tester.tap(find.text('Footfall').first);
      await tester.pumpAndSettle();

      expect(find.text('Press Enclave Marg, Saket'), findsOneWidget);
    });
  });
}
