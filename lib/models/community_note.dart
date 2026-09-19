import 'package:flutter/material.dart';

/// Categories for community crowdsourced notes.
enum NoteCategory {
  all('all', 'All', Icons.grid_view_rounded, Color(0xFF6C2BD9)),
  streetlights('streetlights', 'Streetlights', Icons.lightbulb_rounded, Color(0xFFEAB308)),
  footfall('footfall', 'Footfall', Icons.groups_rounded, Color(0xFF00C2A8)),
  transit('transit', 'Transit & Stations', Icons.directions_subway_rounded, Color(0xFF3B82F6)),
  general('general', 'General', Icons.info_outline_rounded, Color(0xFFFF4D8D));

  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const NoteCategory(this.id, this.label, this.icon, this.color);

  static NoteCategory fromId(String id) {
    return NoteCategory.values.firstWhere(
      (c) => c.id == id,
      orElse: () => NoteCategory.general,
    );
  }
}

/// A crowdsourced anonymous community note with safety indicators.
class CommunityNote {
  final String id;
  final String authorInitial;
  final String authorHandle;
  final String categoryId;
  final String locationTag;
  final String text;
  final String? imagePath;
  final bool isVerified;
  final DateTime timestamp;

  CommunityNote({
    required this.id,
    required this.authorInitial,
    required this.authorHandle,
    required this.categoryId,
    required this.locationTag,
    required this.text,
    this.imagePath,
    this.isVerified = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  NoteCategory get category => NoteCategory.fromId(categoryId);

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorInitial': authorInitial,
        'authorHandle': authorHandle,
        'categoryId': categoryId,
        'locationTag': locationTag,
        'text': text,
        'imagePath': imagePath,
        'isVerified': isVerified,
        'timestamp': timestamp.toIso8601String(),
      };

  factory CommunityNote.fromJson(Map<String, dynamic> json) {
    return CommunityNote(
      id: json['id'] as String? ?? UniqueKey().toString(),
      authorInitial: json['authorInitial'] as String? ?? 'A',
      authorHandle: json['authorHandle'] as String? ?? 'Traveler #100',
      categoryId: json['categoryId'] as String? ?? 'general',
      locationTag: json['locationTag'] as String? ?? 'Delhi NCR',
      text: json['text'] as String? ?? '',
      imagePath: json['imagePath'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
