import '../models/movie.dart';
import '../services/tmdb_service.dart';

class MovieRepository {
  final TmdbService _service;
  MovieRepository(this._service);

  Future<List<Movie>> getTrending() => _service.fetchTrending();

  Future<List<Movie>> search(String query) {
    final q = query.trim();
    return q.isEmpty ? _service.fetchTrending() : _service.searchMovies(q);
  }

  Future<Movie> getDetail(int id) => _service.fetchDetail(id);
}