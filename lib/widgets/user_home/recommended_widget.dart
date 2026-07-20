import 'package:flutter/material.dart';
import 'package:kwikpro/models/technician_model.dart';
import 'package:kwikpro/widgets/user_home/section_header.dart';
import 'user_technician_horizontal_card.dart';

class RecommendedWidget extends StatelessWidget {
  final List<TechnicianModel> technicians;
  final double? userLat;
  final double? userLng;
  final VoidCallback onSeeAll;

  const RecommendedWidget({
    super.key,
    required this.technicians,
    required this.userLat,
    required this.userLng,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {

    if (technicians.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        SectionHeader(
          title: "Recommended For You",
          onSeeAll: onSeeAll,
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: 245,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: technicians.length,
            separatorBuilder: (_, __) =>
            const SizedBox(width: 14),

            itemBuilder: (context, index) {

              final technician = technicians[index];

              final rating =
                  ((technician.avgPriceRating ?? 0) +
                      (technician.avgServiceRating ?? 0)) /
                      2;

              return UserTechnicianHorizontalCard(
                name: technician.name,

                profession: technician.service,

                imageUrl:
                technician.profilePic ?? '',

                rating: rating,

                reviewCount:
                technician.completedJobs ?? 0,

                isVerified:
                technician.isVerified,

                location:
                technician.address,

                distance:
                technician.distanceKm != null
                    ? "${technician.distanceKm!.toStringAsFixed(1)} km away"
                    : null,

                onTap: () {
                  // Open technician profile later
                },
              );
            },
          ),
        ),
      ],
    );
  }
}