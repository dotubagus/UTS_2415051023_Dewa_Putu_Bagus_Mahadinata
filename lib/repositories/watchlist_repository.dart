import '../models/watchlist_item.dart';
import '../services/supabase_service.dart';

class WatchlistRepository {
  final SupabaseService _service;
  WatchlistRepository(this._service);

  Future<List<WatchlistItem>> getAll() => _service.fetchAll();
  Future<WatchlistItem> add(WatchlistItem item) => _service.insert(item);
  Future<WatchlistItem> update(WatchlistItem item) => _service.update(item);
  Future<void> remove(int id) => _service.delete(id);
}