import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Menyimpan data profil lokal: nama, foto profil, dan tanggal bergabung.
/// Foto disimpan sebagai base64 di SharedPreferences (sudah diperkecil saat dipilih).
class ProfileProvider extends ChangeNotifier {
  static const defaultName = 'Dewa Putu Bagus Mahadinata';
  static const _kName = 'profile_name';
  static const _kPhoto = 'profile_photo';
  static const _kJoined = 'profile_joined';

  String _name = defaultName;
  Uint8List? _photo;
  DateTime _joined = DateTime.now();

  String get name => _name;
  Uint8List? get photo => _photo;
  DateTime get joined => _joined;

  String get initial => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _name = prefs.getString(_kName) ?? defaultName;
      final b64 = prefs.getString(_kPhoto);
      _photo = b64 == null ? null : base64Decode(b64);

      final joined = prefs.getString(_kJoined);
      if (joined == null) {
        await prefs.setString(_kJoined, _joined.toIso8601String());
      } else {
        _joined = DateTime.tryParse(joined) ?? _joined;
      }
    } catch (e) {
      debugPrint('Gagal memuat profil: $e');
    }
    notifyListeners();
  }

  /// [photo] null + [removePhoto] true → hapus foto. [photo] null saja → foto tidak diubah.
  Future<void> save({
    required String name,
    Uint8List? photo,
    bool removePhoto = false,
  }) async {
    _name = name.trim().isEmpty ? defaultName : name.trim();
    if (removePhoto) {
      _photo = null;
    } else if (photo != null) {
      _photo = photo;
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kName, _name);
      if (_photo == null) {
        await prefs.remove(_kPhoto);
      } else {
        await prefs.setString(_kPhoto, base64Encode(_photo!));
      }
    } catch (e) {
      debugPrint('Gagal menyimpan profil: $e');
    }
  }
}
