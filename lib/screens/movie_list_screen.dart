import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/movie.dart';
import '../providers/movie_provider.dart';
import '../widgets/movie_card.dart';
import '../widgets/state_views.dart';
import 'movie_detail_screen.dart';

/// Halaman Browse Film:
/// - Pencarian cepat dengan rekomendasi kata kunci populer
/// - Grid film responsif (2–5 kolom sesuai ukuran layar)
class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final _controller = TextEditingController();

  static const _popularKeywords = [
    'Spider-Man',
    'Avatar',
    'Avengers',
    'Batman',
    'Inception',
    'Interstellar',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) {
    if (query.trim().isEmpty) return;
    context.read<MovieProvider>().search(query.trim());
  }

  void _clear() {
    _controller.clear();
    context.read<MovieProvider>().loadTrending();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MovieProvider>();
    final theme = Theme.of(context);

    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 900
        ? 5
        : width >= 600
            ? 4
            : 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Jelajahi Film',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _controller,
              onChanged: (q) => setState(() {}),
              onSubmitted: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Ketik judul film yang ingin kamu cari...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _clear,
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
            ),
          ),

          // Kata Kunci Populer
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _popularKeywords.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final kw = _popularKeywords[i];
                return ActionChip(
                  label: Text(kw, style: const TextStyle(fontSize: 12)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onPressed: () {
                    _controller.text = kw;
                    _search(kw);
                    setState(() {});
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Label Hasil
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              provider.query.isEmpty
                  ? 'Film Populer Rekomendasi'
                  : 'Hasil Pencarian untuk: "${provider.query}"',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // Grid Hasil
          Expanded(child: _buildBody(provider, crossAxisCount)),
        ],
      ),
    );
  }

  Widget _buildBody(MovieProvider provider, int crossAxisCount) {
    switch (provider.status) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        return const StateView.loading();

      case LoadStatus.error:
        return StateView.error(
          message: provider.error ?? 'Terjadi kesalahan saat memuat film.',
          onRetry: () => context.read<MovieProvider>().loadTrending(),
        );

      case LoadStatus.success:
        if (provider.movies.isEmpty) {
          return const StateView.empty(
            message: 'Film tidak ditemukan.\nCoba gunakan kata kunci lain.',
          );
        }
        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.58,
            crossAxisSpacing: 12,
            mainAxisSpacing: 14,
          ),
          itemCount: provider.movies.length,
          itemBuilder: (_, i) {
            final movie = provider.movies[i];
            return MovieCard(
              movie: movie,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MovieDetailScreen(movie: movie),
                ),
              ),
            );
          },
        );
    }
  }
}
