import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global controller managing Low Signal & Battery Mode across the entire app.
class LowSignalController extends ChangeNotifier {
  static final LowSignalController _instance = LowSignalController._internal();
  static LowSignalController get instance => _instance;

  static const String _prefKey = 'saahat_low_signal_mode';
  bool _isLowSignalMode = false;
  bool _isInitialized = false;

  LowSignalController._internal() {
    _loadPreference();
  }

  bool get isLowSignalMode => _isLowSignalMode;
  bool get isInitialized => _isInitialized;

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLowSignalMode = prefs.getBool(_prefKey) ?? false;
      _isInitialized = true;
      notifyListeners();
    } catch (_) {
      _isInitialized = true;
    }
  }

  Future<void> reloadPreference() async {
    await _loadPreference();
  }

  @visibleForTesting
  void resetForTesting([bool value = false]) {
    _isLowSignalMode = value;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> toggleLowSignalMode() async {
    await setLowSignalMode(!_isLowSignalMode);
  }

  Future<void> setLowSignalMode(bool enabled) async {
    if (_isLowSignalMode == enabled) return;
    _isLowSignalMode = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, enabled);
    } catch (_) {}
  }
}
