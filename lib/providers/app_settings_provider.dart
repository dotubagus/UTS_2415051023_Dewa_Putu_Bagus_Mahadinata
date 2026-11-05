import 'package:flutter/material.dart';

/// Provider sederhana untuk mengelola preferensi & fitur aplikasi:
/// - Tema (Terang / Gelap / Sistem)
/// - Pilihan Bahasa (Bahasa Indonesia / English)
/// - Notifikasi pengingat tontonan film di watchlist
class AppSettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  String _language = 'id'; // 'id' = Indonesia, 'en' = English
  bool _notificationsEnabled = true;

  // Menyimpan jadwal pengingat untuk tiap film (movieId -> DateTime jadwal)
  final Map<int, DateTime> _reminders = {};

  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  bool get notificationsEnabled => _notificationsEnabled;
  Map<int, DateTime> get reminders => _reminders;

  bool isDark(BuildContext context) {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleDarkMode(bool enableDark) {
    _themeMode = enableDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }

  void toggleNotifications(bool val) {
    _notificationsEnabled = val;
    notifyListeners();
  }

  // Ambil pengingat untuk film tertentu
  DateTime? getReminder(int movieId) => _reminders[movieId];

  // Pasang jadwal pengingat nonton
  void setReminder(int movieId, DateTime dateTime) {
    _reminders[movieId] = dateTime;
    notifyListeners();
  }

  // Hapus jadwal pengingat nonton
  void removeReminder(int movieId) {
    _reminders.remove(movieId);
    notifyListeners();
  }
}
