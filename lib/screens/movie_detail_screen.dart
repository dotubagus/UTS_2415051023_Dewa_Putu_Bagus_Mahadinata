import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/movie.dart';
import '../providers/watchlist_provider.dart';
import '../repositories/movie_repository.dart';
import '../services/tmdb_service.dart';
import '../widgets/rating_badge.dart';
import 'add_watchlist_screen.dart';

/// Halaman detail film dengan desain modern:
/// - Poster hero dengan dark gradient agar judul dan tombol navigasi terbaca jelas
/// - Tombol kembali yang kontras dan mudah diakses
/// - Fallback otomatis sinopsis lengkap dari TMDB
/// - Tombol tambah ke watchlist yang responsif
class MovieDetailScreen extends StatefulWidget {
  final Movie movie;
  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late Movie _currentMovie;
  bool _loadingDetail = false;

  @override
  void initState() {
    super.initState();
    _currentMovie = widget.movie;

    // Jika sinopsis belum ada (misal karena bahasa Indonesia TMDB kosong),
    // muat detail lengkap dari TMDB dengan fallback otomatis
    if (_currentMovie.overview.trim().isEmpty) {
      _fetchFullDetail();
    }
  }

  Future<void> _fetchFullDetail() async {
    setState(() => _loadingDetail = true);
    try {
      final repo = MovieRepository(TmdbService());
      final detailed = await repo.getDetail(_currentMovie.id);
      if (mounted && detailed.overview.trim().isNotEmpty) {
        setState(() {
          _currentMovie = detailed;
          _loadingDetail = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _loadingDetail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = _currentMovie;
    final inWatchlist =
        context.watch<WatchlistProvider>().isInWatchlist(movie.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ---------- AppBar dengan poster & gradient overlay ----------
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            stretch: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            // Tombol kembali dengan latar belakang lingkaran agar kontras
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.55),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Kembali',
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Text(
                movie.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 4,
                      color: Colors.black87,
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gambar poster / banner dengan Hero animation
                  Hero(
                    tag: 'movie-poster-${movie.id}',
                    child: movie.posterUrl != null
                        ? Image.network(
                            movie.posterUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _posterPlaceholder(context),
                          )
                        : _posterPlaceholder(context),
                  ),

                  // Lapisan gradient gelap agar teks judul & tombol back selalu terbaca
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.65),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.85),
                        ],
                        stops: const [0.0, 0.25, 0.55, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---------- Konten Utama Detail Film ----------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris info: Rating badge + Tahun rilis + ID TMDB
                  Row(
                    children: [
                      RatingBadge.tmdb(movie.voteAverage),
                      const SizedBox(width: 12),
                      if (movie.releaseDate.length >= 4)
                        Chip(
                          avatar: const Icon(Icons.calendar_today_outlined, size: 14),
                          label: Text(movie.releaseDate.substring(0, 4)),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Kotak seksi Sinopsis
                  Text(
                    'Sinopsis',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  Card(
                    elevation: 0,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _loadingDetail
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : Text(
                              movie.overview.trim().isEmpty
                                  ? 'Sinopsis untuk film ini belum tersedia.'
                                  : movie.overview,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(height: 1.5),
                            ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Tombol aksi Tambah ke Watchlist
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: inWatchlist
                        ? OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.bookmark_added_rounded,
                                color: Colors.green),
                            label: const Text(
                              'Sudah Ada di Watchlist',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.green, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          )
                        : FilledButton.icon(
                            onPressed: () => _openAddForm(context),
                            icon: const Icon(Icons.bookmark_add_rounded),
                            label: const Text(
                              'Tambah ke Watchlist',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddForm(BuildContext context) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddWatchlistScreen(movie: _currentMovie)),
    );
  }

  Widget _posterPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.movie_outlined, size: 72, color: Colors.grey),
      ),
    );
  }
}
