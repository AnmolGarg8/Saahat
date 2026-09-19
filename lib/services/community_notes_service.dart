import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/community_note.dart';

/// Service managing local persistence and retrieval of crowdsourced Community Notes.
class CommunityNotesService extends ChangeNotifier {
  static final CommunityNotesService instance = CommunityNotesService._internal();
  CommunityNotesService._internal();

  static const String _storageKey = 'saahat_community_notes';

  List<CommunityNote> _cachedNotes = [];
  bool _isLoaded = false;

  /// Default realistic community seed notes for initial prototype experience.
  static final List<CommunityNote> defaultSeedNotes = [
    CommunityNote(
      id: 'seed-note-1',
      authorInitial: 'P',
      authorHandle: 'Traveler #284',
      categoryId: 'streetlights',
      locationTag: 'Hauz Khas Metro (Gate 2)',
      text:
          'High-mast streetlights are fully functional all along the north footpath towards the main road. Continuous bright lighting and active tea stalls till 11:30 PM.',
      isVerified: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
    ),
    CommunityNote(
      id: 'seed-note-2',
      authorInitial: 'A',
      authorHandle: 'Traveler #109',
      categoryId: 'footfall',
      locationTag: 'Press Enclave Marg, Saket',
      text:
          'Steady pedestrian footfall around Max Hospital entrance and District Centre. Street vendors and auto stands actively present.',
      isVerified: true,
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 24)),
    ),
    CommunityNote(
      id: 'seed-note-3',
      authorInitial: 'M',
      authorHandle: 'Traveler #450',
      categoryId: 'transit',
      locationTag: 'Saket Metro Station (Gate 1)',
      text:
          'Delhi Police assistance booth staffed at the station drop-off bay. Prepaid auto queue active and orderly.',
      isVerified: true,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    CommunityNote(
      id: 'seed-note-4',
      authorInitial: 'S',
      authorHandle: 'Traveler #312',
      categoryId: 'general',
      locationTag: 'Outer Ring Road / IIT Gate',
      text:
          'Wide, unobstructed pedestrian walkway with illuminated signage. Avoided dark side alleys by sticking to the main university boulevard.',
      isVerified: false,
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  /// Loads notes from SharedPreferences or seeds defaults if empty.
  Future<List<CommunityNote>> getNotes({NoteCategory category = NoteCategory.all}) async {
    if (!_isLoaded) {
      await _loadFromStorage();
    }

    if (category == NoteCategory.all) {
      return List.unmodifiable(_cachedNotes);
    }

    return _cachedNotes.where((note) => note.categoryId == category.id).toList();
  }

  /// Adds a new community note, saving it persistently to local storage.
  Future<void> addNote(CommunityNote note) async {
    if (!_isLoaded) {
      await _loadFromStorage();
    }

    // Insert new note at the beginning of the feed
    _cachedNotes.insert(0, note);
    notifyListeners();

    await _saveToStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        _cachedNotes = decoded
            .map((item) => CommunityNote.fromJson(item as Map<String, dynamic>))
            .toList();
        _isLoaded = true;
        return;
      }
    } catch (e) {
      debugPrint('Error loading community notes: $e');
    }

    // Seed defaults if no saved notes exist
    _cachedNotes = List.from(defaultSeedNotes);
    _isLoaded = true;
    await _saveToStorage();
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_cachedNotes.map((n) => n.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Error saving community notes: $e');
    }
  }

  @visibleForTesting
  void resetForTesting(List<CommunityNote>? notes) {
    _cachedNotes = notes != null ? List.from(notes) : List.from(defaultSeedNotes);
    _isLoaded = true;
    notifyListeners();
  }
}
