import 'package:flutter/material.dart';

import '../models/movie.dart';
import 'rating_badge.dart';

/// Kartu film sederhana: poster, rating kecil, judul, dan tahun.
class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;

  /// Jika diisi, tampilkan nomor peringkat besar (gaya "Trending Now" IDLIX).
  final int? rank;

  const MovieCard({super.key, required this.movie, this.onTap, this.rank});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final year = movie.releaseDate.length >= 4
        ? movie.releaseDate.substring(0, 4)
        : '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'movie-poster-${movie.id}',
                    child: _PosterImage(posterUrl: movie.posterUrl),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: RatingBadge.tmdb(movie.voteAverage),
                  ),
                  if (rank != null) ...[
                    // Gradasi gelap di bawah agar nomor terbaca
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xCC000000)],
                            stops: [0.55, 1],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      bottom: 2,
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          fontSize: 44,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            movie.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          if (year.isNotEmpty)
            Text(
              year,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _PosterImage extends StatelessWidget {
  final String? posterUrl;
  const _PosterImage({this.posterUrl});

  @override
  Widget build(BuildContext context) {
    if (posterUrl == null) return _placeholder(context);

    return Image.network(
      posterUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : _placeholder(context),
      errorBuilder: (_, __, ___) => _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          size: 40,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
