import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/watchlist_item.dart';

class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);
  @override
  String toString() => message;
}

class SupabaseService {
  static const _table = 'watchlist';
  SupabaseClient get _db => Supabase.instance.client;

  Future<List<WatchlistItem>> fetchAll() async {
    try {
      final data =
          await _db.from(_table).select().order('created_at', ascending: false);
      return (data as List)
          .map((e) => WatchlistItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException('Gagal memuat watchlist: ${e.message}');
    }
  }

  Future<WatchlistItem> insert(WatchlistItem item) async {
    try {
      final data =
          await _db.from(_table).insert(item.toJson()).select().single();
      return WatchlistItem.fromJson(data);
    } on PostgrestException catch (e) {
      throw DatabaseException('Gagal menyimpan: ${e.message}');
    }
  }

  Future<WatchlistItem> update(WatchlistItem item) async {
    try {
      final data = await _db
          .from(_table)
          .update(item.toJson())
          .eq('id', item.id!)
          .select()
          .single();
      return WatchlistItem.fromJson(data);
    } on PostgrestException catch (e) {
      throw DatabaseException('Gagal memperbarui: ${e.message}');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _db.from(_table).delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw DatabaseException('Gagal menghapus: ${e.message}');
    }
  }
}