class Movie {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final double voteAverage;
  final String releaseDate;
  /// Daftar id genre film dari TMDB (dipakai untuk filter chip genre).
  final List<int> genreIds;

  const Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.voteAverage,
    required this.releaseDate,
    this.genreIds = const [],
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    // genre_ids tersedia di list, genre_ids kosong di endpoint detail (pakai genres)
    final rawIds = json['genre_ids'] as List<dynamic>?;
    final rawGenres = json['genres'] as List<dynamic>?;
    final ids = rawIds?.map((e) => (e as num).toInt()).toList() ??
        rawGenres?.map((e) => ((e as Map<String, dynamic>)['id'] as num).toInt()).toList() ??
        <int>[];

    return Movie(
      id: json['id'] as int,
      title: (json['title'] ?? json['name'] ?? 'Tanpa judul') as String,
      overview: (json['overview'] ?? '') as String,
      posterPath: json['poster_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      releaseDate: (json['release_date'] ?? '') as String,
      genreIds: ids,
    );
  }

  /// null jika film tidak punya poster → tampilkan placeholder di UI.
  String? get posterUrl => (posterPath == null || posterPath!.isEmpty)
      ? null
      : 'https://image.tmdb.org/t/p/w500$posterPath';
}