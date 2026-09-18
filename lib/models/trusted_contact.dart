import 'package:flutter/material.dart';

class TrustedContact {
  final String id;
  final String name;
  final String relation;
  final String phone;
  final Color avatarColor;

  const TrustedContact({
    required this.id,
    required this.name,
    required this.relation,
    required this.phone,
    required this.avatarColor,
  });

  String get displayName => '$name ($relation)';

  String get initials {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  /// Default contacts requested in prompt:
  /// Mom/Anjali, Sara/Roommate, Priya/Sister, Elena/Colleague (+91 98765 43210 style)
  static const List<TrustedContact> defaultContacts = [
    TrustedContact(
      id: 'contact_mom',
      name: 'Anjali',
      relation: 'Mom',
      phone: '+91 98765 43210',
      avatarColor: Color(0xFF6C2BD9), // Purple
    ),
    TrustedContact(
      id: 'contact_roommate',
      name: 'Sara',
      relation: 'Roommate',
      phone: '+91 98123 45678',
      avatarColor: Color(0xFFFF4D8D), // Magenta
    ),
    TrustedContact(
      id: 'contact_sister',
      name: 'Priya',
      relation: 'Sister',
      phone: '+91 98234 56789',
      avatarColor: Color(0xFF00C2A8), // Teal
    ),
    TrustedContact(
      id: 'contact_colleague',
      name: 'Elena',
      relation: 'Colleague',
      phone: '+91 98345 67890',
      avatarColor: Color(0xFFFFB300), // Amber
    ),
  ];
}
