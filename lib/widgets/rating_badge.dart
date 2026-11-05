import 'package:flutter/material.dart';

/// Badge rating ala IDLIX: pil gelap transparan dengan bintang kuning.
/// - [RatingBadge.tmdb]: rating TMDB (0–10)
/// - [RatingBadge.user]: rating pengguna (1–10)
class RatingBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final Color iconColor;

  const RatingBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.icon = Icons.star_rounded,
    this.iconColor = const Color(0xFFFFC107),
  });

  factory RatingBadge.tmdb(double value) {
    return RatingBadge(
      label: value.toStringAsFixed(1),
      backgroundColor: Colors.black.withOpacity(0.72),
      foregroundColor: Colors.white,
    );
  }

  factory RatingBadge.user(int value) {
    return RatingBadge(
      label: '$value/10',
      backgroundColor: Colors.black.withOpacity(0.72),
      foregroundColor: Colors.white,
      icon: Icons.person_rounded,
      iconColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
