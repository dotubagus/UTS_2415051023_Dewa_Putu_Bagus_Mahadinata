import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/movie_provider.dart';
import '../widgets/state_view.dart';

/// Screen sementara untuk mengetes TMDB. Nanti diganti Home yang sebenarnya.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final movies = context.watch<MovieProvider>();

    final Widget body;
    switch (movies.status) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        body = const StateView.loading();
      case LoadStatus.error:
        body = StateView.error(
          message: movies.error ?? 'Terjadi kesalahan.',
          onRetry: () => context.read<MovieProvider>().loadTrending(),
        );
      case LoadStatus.success:
        body = movies.isEmpty
            ? const StateView.empty(message: 'Film tidak ditemukan.')
            : ListView.builder(
                itemCount: movies.movies.length,
                itemBuilder: (_, i) {
                  final m = movies.movies[i];
                  return ListTile(
                    title: Text(m.title),
                    subtitle: Text(
                        'Rating TMDB: ${m.voteAverage.toStringAsFixed(1)}'),
                  );
                },
              );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('CineList')),
      body: body,
    );
  }
}