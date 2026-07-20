import 'package:flutter/material.dart';

import '../../models/technician_model.dart';
import '../../screens/user/view_technician_profile_screen.dart';
import '../../core/utils/distance_helper.dart';
import 'section_header.dart';
import 'user_technician_horizontal_card.dart';

class RecentlyBookedWidget extends StatelessWidget {
  final List<TechnicianModel> technicians;
  final double? userLat;
  final double? userLng;
  final VoidCallback? onSeeAll;

  const RecentlyBookedWidget({
    super.key,
    required this.technicians,
    required this.userLat,
    required this.userLng,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (technicians.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayTechnicians = technicians.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Recently Booked",
          count: technicians.length,
          subtitle: "Technicians customers are booking lately",
          onSeeAll: onSeeAll,
        ),

        const SizedBox(height: 14),

        SizedBox(
          height: 220,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: displayTechnicians.length,
            separatorBuilder: (_, __) =>
            const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final technician = displayTechnicians[index];

              return UserTechnicianHorizontalCard(
                name: technician.name,
                profession: technician.service,
                imageUrl: technician.profilePic ?? "",
                rating: technician.avgServiceRating ?? 0,
                reviewCount: technician.completedJobs ?? 0,
                isVerified: technician.isVerified,
                distance: technician.distanceKm == null
                    ? null
                    : DistanceHelper.formatEta(
                  technician.distanceKm!,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ViewTechnicianProfileScreen(
                        technician: technician,
                        userLat: userLat,
                        userLng: userLng,
                        serviceLocationAddress: "",
                        issueDescription: "",
                        imageUrl: "",
                        selectedSkills: const [],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}