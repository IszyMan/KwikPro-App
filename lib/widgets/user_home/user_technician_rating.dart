import 'package:flutter/material.dart';

class UserTechnicianRating extends StatelessWidget {
  final double rating;
  final int reviewCount;

  const UserTechnicianRating({
    super.key,
    required this.rating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    final displayRating = rating.clamp(0.0, 5.0);

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        children: [
          ..._buildStars(displayRating),

          const SizedBox(width: 8),

          Text(
            displayRating.toStringAsFixed(1),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),

          const SizedBox(width: 4),

          Text(
            "(Jobs: $reviewCount)",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStars(double rating) {
    final rounded = (rating * 2).round() / 2;

    final fullStars = rounded.floor();
    final hasHalfStar = (rounded - fullStars) == 0.5;
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    return [
      for (int i = 0; i < fullStars; i++)
        const Icon(
          Icons.star,
          color: Colors.amber,
          size: 17,
        ),

      if (hasHalfStar)
        const Icon(
          Icons.star_half,
          color: Colors.amber,
          size: 17,
        ),

      for (int i = 0; i < emptyStars; i++)
        const Icon(
          Icons.star_border,
          color: Colors.amber,
          size: 17,
        ),
    ];
  }
}