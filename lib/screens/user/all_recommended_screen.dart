import 'package:flutter/material.dart';
import '../../models/technician_model.dart';
import '../../widgets/user_home/user_technician_horizontal_card.dart';

class AllRecommendedScreen extends StatelessWidget {
  final List<TechnicianModel> technicians;

  const AllRecommendedScreen({
    super.key,
    required this.technicians,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Recommended For You",
        ),
        centerTitle: true,
      ),

      body: technicians.isEmpty
          ? const Center(
        child: Text(
          "No recommendations available yet",
        ),
      )

          : ListView.separated(
        padding: const EdgeInsets.all(16),

        itemCount: technicians.length,

        separatorBuilder: (_, __) =>
        const SizedBox(height: 14),

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
              // Navigate to technician profile later
            },
          );
        },
      ),
    );
  }
}