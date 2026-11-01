import 'package:flutter/foundation.dart';

import '../models/movie.dart';
import '../repositories/movie_repository.dart';

enum LoadStatus { initial, loading, success, error }

class MovieProvider extends ChangeNotifier {
  final MovieRepository _repository;
  MovieProvider(this._repository);

  LoadStatus _status = LoadStatus.initial;
  List<Movie> _movies = [];
  String? _error;
  String _query = '';

  LoadStatus get status => _status;
  List<Movie> get movies => _movies;
  String? get error => _error;
  String get query => _query;
  bool get isEmpty => _status == LoadStatus.success && _movies.isEmpty;

  Future<void> loadTrending() => _load(() => _repository.getTrending());

  Future<void> search(String query) {
    _query = query;
    return _load(() => _repository.search(query));
  }

  Future<void> _load(Future<List<Movie>> Function() action) async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _movies = await action();
      _status = LoadStatus.success;
    } catch (e) {
      _error = e.toString();
      _status = LoadStatus.error;
    }
    notifyListeners();
  }
}