import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/trusted_contact.dart';

/// Service managing ETA message generation, active trip state,
/// and native SMS app dispatch.
class EtaSharingService extends ChangeNotifier {
  static final EtaSharingService instance = EtaSharingService._internal();
  EtaSharingService._internal();

  bool _isTripActive = false;
  TrustedContact? _activeContact;
  String _activeRouteName = 'Main Arterial Route';
  int _activeDurationMinutes = 25;
  TimeOfDay _activeExpectedArrival = const TimeOfDay(hour: 23, minute: 45);
  DateTime? _tripStartTime;

  bool get isTripActive => _isTripActive;
  TrustedContact? get activeContact => _activeContact;
  String get activeRouteName => _activeRouteName;
  int get activeDurationMinutes => _activeDurationMinutes;
  TimeOfDay get activeExpectedArrival => _activeExpectedArrival;
  DateTime? get tripStartTime => _tripStartTime;

  /// Formats the official message requested:
  /// "I'm heading home via [route name] ([time] mins), expected arrival by [time]. Powered by Saahat."
  static String formatEtaMessage({
    required String routeName,
    required int durationMinutes,
    required String formattedArrivalTime,
  }) {
    return "I'm heading home via $routeName ($durationMinutes mins), expected arrival by $formattedArrivalTime. Powered by Saahat.";
  }

  /// Formats safe arrival message
  static String formatArrivedSafelyMessage({required String contactName}) {
    return "I've arrived safely! Thanks for looking out. ❤️ - sent via Saahat";
  }

  /// Launches native SMS app pre-filled with phone and message
  static Future<bool> openSmsApp({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // Android standard URI for SMS with body parameter
    final uriWithParam = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    try {
      if (await canLaunchUrl(uriWithParam)) {
        return await launchUrl(
          uriWithParam,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {}

    // Fallback: direct query string formatting
    try {
      final fallbackUri = Uri.parse('sms:$cleanPhone?body=${Uri.encodeComponent(message)}');
      return await launchUrl(
        fallbackUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }

  /// Mark trip as started and actively shared
  void startTrip({
    required TrustedContact contact,
    required String routeName,
    required int durationMinutes,
    required TimeOfDay expectedArrival,
  }) {
    _isTripActive = true;
    _activeContact = contact;
    _activeRouteName = routeName;
    _activeDurationMinutes = durationMinutes;
    _activeExpectedArrival = expectedArrival;
    _tripStartTime = DateTime.now();
    notifyListeners();
  }

  /// Mark user as arrived safely
  void markArrivedSafely() {
    _isTripActive = false;
    notifyListeners();
  }

  /// Cancel active sharing
  void cancelSharing() {
    _isTripActive = false;
    _activeContact = null;
    notifyListeners();
  }
}
