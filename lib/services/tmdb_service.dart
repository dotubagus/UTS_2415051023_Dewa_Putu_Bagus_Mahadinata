import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/movie.dart';

class TmdbException implements Exception {
  final String message;
  TmdbException(this.message);
  @override
  String toString() => message;
}

class TmdbService {
  static const _host = 'api.themoviedb.org';
  String get _apiKey => dotenv.env['TMDB_API_KEY'] ?? '';

  Future<List<Movie>> fetchTrending() async {
    final list = await _getList('/3/trending/movie/week', {});
    // Jika sebagian besar film tidak memiliki sinopsis di id-ID, fallback ke en-US
    if (list.isNotEmpty && list.where((m) => m.overview.isNotEmpty).length < (list.length / 2)) {
      try {
        return await _getList('/3/trending/movie/week', {}, 'en-US');
      } catch (_) {}
    }
    return list;
  }

  Future<List<Movie>> searchMovies(String query) async {
    final list = await _getList('/3/search/movie', {'query': query});
    if (list.isNotEmpty && list.where((m) => m.overview.isNotEmpty).length < (list.length / 2)) {
      try {
        return await _getList('/3/search/movie', {'query': query}, 'en-US');
      } catch (_) {}
    }
    return list;
  }

  Future<Movie> fetchDetail(int id) async {
    final json = await _get('/3/movie/$id', {});
    var movie = Movie.fromJson(json);
    // Jika sinopsis bahasa Indonesia kosong di TMDB, coba ambil dalam bahasa Inggris
    if (movie.overview.trim().isEmpty) {
      try {
        final enJson = await _get('/3/movie/$id', {}, 'en-US');
        final enMovie = Movie.fromJson(enJson);
        if (enMovie.overview.trim().isNotEmpty) {
          movie = Movie(
            id: movie.id,
            title: movie.title.isNotEmpty ? movie.title : enMovie.title,
            overview: enMovie.overview,
            posterPath: movie.posterPath ?? enMovie.posterPath,
            voteAverage: movie.voteAverage > 0 ? movie.voteAverage : enMovie.voteAverage,
            releaseDate: movie.releaseDate.isNotEmpty ? movie.releaseDate : enMovie.releaseDate,
            genreIds: movie.genreIds.isNotEmpty ? movie.genreIds : enMovie.genreIds,
          );
        }
      } catch (_) {}
    }
    return movie;
  }

  Future<List<Movie>> _getList(String path, Map<String, String> params, [String lang = 'id-ID']) async {
    final json = await _get(path, params, lang);
    final results = (json['results'] as List<dynamic>? ?? []);
    return results
        .map((e) => Movie.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> _get(
      String path, Map<String, String> params, [String lang = 'id-ID']) async {
    final uri = Uri.https(_host, path, {
      'api_key': _apiKey,
      'language': lang,
      ...params,
    });
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      if (res.statusCode == 401) {
        throw TmdbException('API key TMDB tidak valid.');
      }
      throw TmdbException('Gagal memuat data (kode ${res.statusCode}).');
    } on SocketException {
      throw TmdbException('Tidak ada koneksi internet.');
    } on TimeoutException {
      throw TmdbException('Koneksi terlalu lama. Coba lagi.');
    } on FormatException {
      throw TmdbException('Format respons tidak valid.');
    }
  }
}
