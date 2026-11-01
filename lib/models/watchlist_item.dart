class WatchlistItem {
  final int? id; // null sebelum disimpan ke database
  final int movieId;
  final String title;
  final String? posterUrl;
  final int rating;
  final String? note;
  final bool watched;
  final DateTime? createdAt;

  const WatchlistItem({
    this.id,
    required this.movieId,
    required this.title,
    this.posterUrl,
    required this.rating,
    this.note,
    this.watched = false,
    this.createdAt,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: json['id'] as int,
      movieId: json['movie_id'] as int,
      title: json['title'] as String,
      posterUrl: json['poster_url'] as String?,
      rating: json['rating'] as int,
      note: json['note'] as String?,
      watched: json['watched'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );
  }

  /// Tanpa id & created_at: keduanya dibuat otomatis oleh database.
  Map<String, dynamic> toJson() => {
        'movie_id': movieId,
        'title': title,
        'poster_url': posterUrl,
        'rating': rating,
        'note': note,
        'watched': watched,
      };

  WatchlistItem copyWith({int? rating, String? note, bool? watched}) {
    return WatchlistItem(
      id: id,
      movieId: movieId,
      title: title,
      posterUrl: posterUrl,
      rating: rating ?? this.rating,
      note: note ?? this.note,
      watched: watched ?? this.watched,
      createdAt: createdAt,
    );
  }
}