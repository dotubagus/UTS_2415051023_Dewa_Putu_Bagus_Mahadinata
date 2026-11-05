import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/movie.dart';
import '../models/watchlist_item.dart';
import '../providers/app_settings_provider.dart';
import '../providers/movie_provider.dart' show LoadStatus;
import '../providers/watchlist_provider.dart';
import '../widgets/rating_badge.dart';
import '../widgets/state_views.dart';
import 'edit_watchlist_screen.dart';
import 'movie_detail_screen.dart';

/// Halaman Watchlist: menampilkan semua film yang sudah disimpan pengguna.
/// Mendukung:
/// - Pasang pengingat jadwal nonton film khusus untuk film yang ingin ditonton
/// - Ketuk item untuk langsung membuka review/rating
/// - CRUD (edit dan hapus dengan konfirmasi)
/// - Filter tab: Semua / Belum Ditonton / Sudah Ditonton
/// - Fitur acak: pilih film belum ditonton secara random
class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WatchlistProvider>().load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Pasang notifikasi pengingat jadwal menonton film
  Future<void> _setReminder(BuildContext context, WatchlistItem item) async {
    final now = DateTime.now();

    // 1. Pilih Tanggal Pengingat
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'PILIH TANGGAL NONTON',
      confirmText: 'LANJUT',
    );
    if (pickedDate == null || !mounted) return;

    // 2. Pilih Jam Pengingat
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 2))),
      helpText: 'PILIH JAM PENGINGAT',
      confirmText: 'PASANG PENGINGAT',
    );
    if (pickedTime == null || !mounted) return;

    final scheduled = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    context.read<AppSettingsProvider>().setReminder(item.movieId, scheduled);

    final hourStr = pickedTime.hour.toString().padLeft(2, '0');
    final minuteStr = pickedTime.minute.toString().padLeft(2, '0');
    final dateStr = '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';

    if (!mounted) return;

    // Notifikasi Dialog Konfirmasi Pengingat
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.notifications_active_rounded,
              color: Colors.amber.shade800, size: 40),
        ),
        title: const Text('🔔 Pengingat Berhasil Disetel!',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Aplikasi telah menjadwalkan notifikasi pengingat untuk menonton:\n"${item.title}"',
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.3),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.primaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '$dateStr pukul $hourStr:$minuteStr WIB',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Siap, Terima Kasih!'),
          ),
        ],
      ),
    );
  }

  /// Hapus pengingat nonton
  void _cancelReminder(BuildContext context, WatchlistItem item) {
    context.read<AppSettingsProvider>().removeReminder(item.movieId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pengingat menonton "${item.title}" dibatalkan.'),
      ),
    );
  }

  /// Hapus item dengan konfirmasi AlertDialog.
  Future<void> _confirmDelete(BuildContext context, WatchlistItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus dari Watchlist?'),
        content: Text(
            '"${item.title}" akan dihapus dari watchlist kamu. Aksi ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final error = await context.read<WatchlistProvider>().remove(item.id!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error == null
            ? '${item.title} dihapus dari watchlist.'
            : 'Gagal menghapus: $error'),
        backgroundColor: error == null ? null : Colors.red,
      ),
    );
  }

  /// Buka detail film TMDB
  void _openMovieDetail(BuildContext context, WatchlistItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MovieDetailScreen(
          movie: Movie(
            id: item.movieId,
            title: item.title,
            overview: '', // otomatis di-fetch lengkap oleh MovieDetailScreen
            posterPath: item.posterUrl != null ? '' : null,
            voteAverage: 0,
            releaseDate: '',
          ),
        ),
      ),
    );
  }

  /// Pilih film belum ditonton secara acak dan tampilkan dialog.
  void _pickRandom(List<WatchlistItem> all) {
    final unwatched = all.where((e) => !e.watched).toList();

    if (unwatched.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua film di watchlist sudah ditonton! 🎉')),
      );
      return;
    }

    final pick = unwatched[Random().nextInt(unwatched.length)];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🎲 Rekomendasi Acak'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tonton film ini malam ini:'),
            const SizedBox(height: 12),
            Text(
              pick.title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            RatingBadge.user(pick.rating),
            if (pick.note != null && pick.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(pick.note!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openEdit(context, pick);
            },
            child: const Text('Lihat Review'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchlistProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: provider.items.isNotEmpty
                ? () => _pickRandom(provider.items)
                : null,
            icon: const Icon(Icons.casino_outlined),
            tooltip: 'Pilih film acak',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Belum Ditonton'),
            Tab(text: 'Sudah Ditonton'),
          ],
        ),
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(WatchlistProvider provider) {
    switch (provider.status) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        return const StateView.loading();

      case LoadStatus.error:
        return StateView.error(
          message: provider.error ?? 'Terjadi kesalahan.',
          onRetry: () => context.read<WatchlistProvider>().load(),
        );

      case LoadStatus.success:
        if (provider.items.isEmpty) {
          return const StateView.empty(
            message: 'Watchlist kamu masih kosong.\nCari film favoritmu di Home atau Browse dan tambahkan ke sini!',
          );
        }

        return TabBarView(
          controller: _tabController,
          children: [
            // Tab 0: Semua
            _WatchlistList(
              items: provider.items,
              onEdit: (item) => _openEdit(context, item),
              onDetail: (item) => _openMovieDetail(context, item),
              onReminder: (item) => _setReminder(context, item),
              onCancelReminder: (item) => _cancelReminder(context, item),
              onDelete: (item) => _confirmDelete(context, item),
              emptyMessage: 'Belum ada film di watchlist.',
            ),
            // Tab 1: Belum ditonton
            _WatchlistList(
              items: provider.items.where((e) => !e.watched).toList(),
              onEdit: (item) => _openEdit(context, item),
              onDetail: (item) => _openMovieDetail(context, item),
              onReminder: (item) => _setReminder(context, item),
              onCancelReminder: (item) => _cancelReminder(context, item),
              onDelete: (item) => _confirmDelete(context, item),
              emptyMessage: 'Semua film di watchlist sudah kamu tonton! 🎉',
            ),
            // Tab 2: Sudah ditonton
            _WatchlistList(
              items: provider.items.where((e) => e.watched).toList(),
              onEdit: (item) => _openEdit(context, item),
              onDetail: (item) => _openMovieDetail(context, item),
              onReminder: (item) => _setReminder(context, item),
              onCancelReminder: (item) => _cancelReminder(context, item),
              onDelete: (item) => _confirmDelete(context, item),
              emptyMessage: 'Belum ada film yang kamu tandai sudah ditonton.',
            ),
          ],
        );
    }
  }

  Future<void> _openEdit(BuildContext context, WatchlistItem item) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditWatchlistScreen(item: item)),
    );
  }
}

// ─────────────────────────────────────────────────────────────
/// Sub-widget: daftar item watchlist
// ─────────────────────────────────────────────────────────────
class _WatchlistList extends StatelessWidget {
  final List<WatchlistItem> items;
  final void Function(WatchlistItem) onEdit;
  final void Function(WatchlistItem) onDetail;
  final void Function(WatchlistItem) onReminder;
  final void Function(WatchlistItem) onCancelReminder;
  final void Function(WatchlistItem) onDelete;
  final String emptyMessage;

  const _WatchlistList({
    required this.items,
    required this.onEdit,
    required this.onDetail,
    required this.onReminder,
    required this.onCancelReminder,
    required this.onDelete,
    this.emptyMessage = 'Watchlist kamu kosong.',
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return StateView.empty(message: emptyMessage);
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      itemCount: items.length,
      itemBuilder: (ctx, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          elevation: 0,
          color: Theme.of(ctx).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Theme.of(ctx).colorScheme.outlineVariant.withOpacity(0.2),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: _WatchlistTile(
            item: items[i],
            onTap: () => onEdit(items[i]),
            onEdit: () => onEdit(items[i]),
            onDetail: () => onDetail(items[i]),
            onReminder: () => onReminder(items[i]),
            onCancelReminder: () => onCancelReminder(items[i]),
            onDelete: () => onDelete(items[i]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
/// Sub-widget: satu baris item watchlist.
// ─────────────────────────────────────────────────────────────
class _WatchlistTile extends StatelessWidget {
  final WatchlistItem item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDetail;
  final VoidCallback onReminder;
  final VoidCallback onCancelReminder;
  final VoidCallback onDelete;

  const _WatchlistTile({
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDetail,
    required this.onReminder,
    required this.onCancelReminder,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Jika film sudah selesai ditonton, jadwal pengingat tidak ditampilkan
    final reminder = item.watched
        ? null
        : context.watch<AppSettingsProvider>().getReminder(item.movieId);

    return ListTile(
      onTap: onTap,
      leading: _PosterThumb(posterUrl: item.posterUrl),
      title: Text(
        item.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (item.watched)
                RatingBadge.user(item.rating)
              else ...[
                // Badge Status Ingin Ditonton
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark_outline_rounded,
                          size: 13,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        'Ingin Ditonton',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Pill Jadwal Pengingat (Hanya jika sudah disetel, tanpa emot jam)
                if (reminder != null)
                  InkWell(
                    onTap: onReminder,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.amber.shade700, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.alarm_on_rounded,
                              size: 12, color: Colors.amber.shade800),
                          const SizedBox(width: 4),
                          Text(
                            '${reminder.day}/${reminder.month} ${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')} WIB',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
          if (item.note != null && item.note!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.note!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tombol Pengingat Nonton HANYA untuk film yang ingin ditonton
          if (!item.watched)
            IconButton(
              icon: Icon(
                reminder != null
                    ? Icons.notifications_active_rounded
                    : Icons.alarm_add_rounded,
                color: reminder != null
                    ? Colors.amber.shade800
                    : Theme.of(context).colorScheme.primary,
                size: 22,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              tooltip: reminder != null
                  ? 'Ubah Jadwal Pengingat'
                  : 'Atur Jadwal Pengingat',
              onPressed: onReminder,
            ),
          if (item.watched)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 20),
            ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: 'Opsi',
            onSelected: (val) {
              if (val == 'edit') onEdit();
              if (val == 'detail') onDetail();
              if (val == 'reminder') onReminder();
              if (val == 'cancel_reminder') onCancelReminder();
              if (val == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Ubah Review & Rating'),
                  ],
                ),
              ),
              if (!item.watched) ...[
                PopupMenuItem(
                  value: 'reminder',
                  child: Row(
                    children: [
                      Icon(
                        reminder != null
                            ? Icons.alarm_on_rounded
                            : Icons.alarm_add_rounded,
                        size: 20,
                        color: Colors.amber.shade800,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        reminder != null
                            ? 'Ubah Jadwal Nonton'
                            : 'Atur Jadwal Nonton',
                      ),
                    ],
                  ),
                ),
                if (reminder != null)
                  const PopupMenuItem(
                    value: 'cancel_reminder',
                    child: Row(
                      children: [
                        Icon(Icons.alarm_off_rounded, size: 20, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Hapus Pengingat'),
                      ],
                    ),
                  ),
              ],
              const PopupMenuItem(
                value: 'detail',
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Detail Film'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hapus', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      isThreeLine: item.note != null && item.note!.trim().isNotEmpty,
    );
  }
}

class _PosterThumb extends StatelessWidget {
  final String? posterUrl;
  const _PosterThumb({this.posterUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: posterUrl != null
          ? Image.network(
              posterUrl!,
              width: 52,
              height: 78,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(context),
            )
          : _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: 52,
      height: 78,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.movie_outlined, size: 28),
    );
  }
}
