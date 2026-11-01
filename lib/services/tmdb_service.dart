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

  Future<List<Movie>> fetchTrending() =>
      _getList('/3/trending/movie/week', {});

  Future<List<Movie>> searchMovies(String query) =>
      _getList('/3/search/movie', {'query': query});

  Future<Movie> fetchDetail(int id) async {
    final json = await _get('/3/movie/$id', {});
    return Movie.fromJson(json);
  }

  Future<List<Movie>> _getList(String path, Map<String, String> params) async {
    final json = await _get(path, params);
    final results = (json['results'] as List<dynamic>? ?? []);
    return results
        .map((e) => Movie.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> _get(
      String path, Map<String, String> params) async {
    final uri = Uri.https(_host, path, {
      'api_key': _apiKey,
      'language': 'id-ID',
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