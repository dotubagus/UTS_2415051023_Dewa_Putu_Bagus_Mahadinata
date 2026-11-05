import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart' show kIdlixRed;
import '../models/movie.dart';
import '../providers/movie_provider.dart';
import '../widgets/movie_card.dart';
import '../widgets/rating_badge.dart';
import '../widgets/state_views.dart';
import 'add_watchlist_screen.dart';
import 'movie_detail_screen.dart';

/// Daftar genre film TMDB
const _genres = [
  _Genre('Semua', 0),
  _Genre('Action', 28),
  _Genre('Drama', 18),
  _Genre('Comedy', 35),
  _Genre('Horror', 27),
  _Genre('Sci-Fi', 878),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedGenreId = 0;

  List<Movie> _applyGenreFilter(List<Movie> movies) {
    if (_selectedGenreId == 0) return movies;
    return movies.where((m) => m.genreIds.contains(_selectedGenreId)).toList();
  }

  void _open(Movie movie) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
      );

  void _addToWatchlist(Movie movie) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddWatchlistScreen(movie: movie)),
      );

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MovieProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 700;
    final crossAxisCount = width >= 1100 ? 6 : width >= 700 ? 4 : 3;

    return Scaffold(
      // Di layar lebar logo sudah ada di navbar pill (MainShell)
      appBar: isWide
          ? null
          : AppBar(
              title: const Text(
                'CINELIST',
                style: TextStyle(
                  color: kIdlixRed,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ),
      body: _buildBody(provider, isWide, crossAxisCount),
    );
  }

  Widget _buildBody(MovieProvider provider, bool isWide, int cols) {
    switch (provider.status) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        return const StateView.loading();
      case LoadStatus.error:
        return StateView.error(
          message: provider.error ?? 'Terjadi kesalahan saat memuat data TMDB.',
          onRetry: () => context.read<MovieProvider>().loadTrending(),
        );
      case LoadStatus.success:
        final all = provider.movies;
        final filtered = _applyGenreFilter(all);
        final hero = all.take(6).toList();
        final ranked = filtered.take(10).toList();

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            if (hero.isNotEmpty)
              SliverToBoxAdapter(
                child: _HeroCarousel(
                  movies: hero,
                  isWide: isWide,
                  onWatch: _addToWatchlist,
                ),
              ),
            SliverToBoxAdapter(child: _genreChips(context)),
            if (filtered.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: StateView.empty(
                  message: 'Tidak ada film yang cocok dengan filter ini.',
                ),
              )
            else ...[
              SliverToBoxAdapter(child: _sectionTitle('Trending Now')),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: isWide ? 290 : 230,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: ranked.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => SizedBox(
                      width: isWide ? 170 : 130,
                      child: MovieCard(
                        movie: ranked[i],
                        rank: i + 1,
                        onTap: () => _open(ranked[i]),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _sectionTitle('Semua Film')),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    childAspectRatio: 0.52,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => MovieCard(
                    movie: filtered[i],
                    onTap: () => _open(filtered[i]),
                  ),
                ),
              ),
            ],
          ],
        );
    }
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Text(
          text,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
      );

  Widget _genreChips(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _genres.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final g = _genres[i];
          final selected = _selectedGenreId == g.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedGenreId = g.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: selected
                    ? kIdlixRed
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                g.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Banner hero ala IDLIX: badge MOVIE, judul besar, rating, sinopsis,
/// tombol "Watch Now", dan indikator titik (yang aktif memanjang merah).
class _HeroCarousel extends StatefulWidget {
  final List<Movie> movies;
  final bool isWide;
  final ValueChanged<Movie> onWatch;
  const _HeroCarousel({
    required this.movies,
    required this.isWide,
    required this.onWatch,
  });

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final height = widget.isWide ? 440.0 : 420.0;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.movies.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => _slide(widget.movies[i], bg),
          ),
          Positioned(
            left: 24,
            bottom: 16,
            child: Row(
              children: [
                for (var i = 0; i < widget.movies.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 8),
                    width: i == _page ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? kIdlixRed : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _slide(Movie m, Color bg) {
    final year = m.releaseDate.length >= 4 ? m.releaseDate.substring(0, 4) : '';
    final isWide = widget.isWide;

    final poster = m.posterUrl == null
        ? Container(color: const Color(0xFF1B1B1B))
        : Image.network(
            m.posterUrl!,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1B1B1B)),
          );

    return Stack(
      fit: StackFit.expand,
      children: [
        // Poster: kanan (layar lebar) atau penuh (HP)
        if (isWide)
          Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(widthFactor: 0.55, child: poster),
          )
        else
          poster,
        // Gradasi pemudar ke latar
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: isWide ? Alignment.centerLeft : Alignment.topCenter,
              end: isWide ? Alignment.centerRight : Alignment.bottomCenter,
              colors: isWide
                  ? [bg, bg, bg.withOpacity(0.2)]
                  : [bg.withOpacity(0.1), bg.withOpacity(0.75), bg],
              stops: isWide ? const [0, 0.45, 1] : const [0, 0.45, 0.85],
            ),
          ),
        ),
        // Bagian bawah memudar ke latar agar menyatu dengan konten
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bg.withOpacity(0), bg],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 44),
          child: Align(
            alignment: isWide ? Alignment.centerLeft : Alignment.bottomLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 560 : 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kIdlixRed,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'MOVIE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    m.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isWide ? 44 : 32,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      RatingBadge.tmdb(m.voteAverage),
                      if (year.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Text(year,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                  if (m.overview.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      m.overview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => widget.onWatch(m),
                    icon: const Icon(Icons.bookmark_add_rounded, size: 20),
                    label: const Text(
                      'Tambah ke Watchlist',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: kIdlixRed,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Genre {
  final String name;
  final int id;
  const _Genre(this.name, this.id);
}
