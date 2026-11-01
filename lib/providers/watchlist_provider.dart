import 'package:flutter/foundation.dart';

import '../models/watchlist_item.dart';
import '../repositories/watchlist_repository.dart';
import 'movie_provider.dart' show LoadStatus;

class WatchlistProvider extends ChangeNotifier {
  final WatchlistRepository _repository;
  WatchlistProvider(this._repository);

  LoadStatus _status = LoadStatus.initial;
  List<WatchlistItem> _items = [];
  String? _error;

  LoadStatus get status => _status;
  List<WatchlistItem> get items => _items;
  String? get error => _error;
  bool get isEmpty => _status == LoadStatus.success && _items.isEmpty;

  /// Shared state: dipakai Detail (sudah tersimpan?) dan Watchlist.
  bool isInWatchlist(int movieId) => _items.any((e) => e.movieId == movieId);

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _items = await _repository.getAll();
      _status = LoadStatus.success;
    } catch (e) {
      _error = e.toString();
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  /// Mengembalikan null jika sukses, atau pesan error untuk SnackBar.
  Future<String?> add(WatchlistItem item) async {
    try {
      final saved = await _repository.add(item);
      _items = [saved, ..._items];
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> update(WatchlistItem item) async {
    try {
      final saved = await _repository.update(item);
      _items = _items.map((e) => e.id == saved.id ? saved : e).toList();
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> remove(int id) async {
    try {
      await _repository.remove(id);
      _items = _items.where((e) => e.id != id).toList();
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}