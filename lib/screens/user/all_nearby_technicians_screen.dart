import 'package:flutter/material.dart';

import '../../models/technician_model.dart';
import '../../widgets/user_home/user_technician_horizontal_card.dart';

class AllNearbyTechniciansScreen extends StatelessWidget {
  final List<TechnicianModel> technicians;

  const AllNearbyTechniciansScreen({
    super.key,
    required this.technicians,
  });

  @override
  Widget build(BuildContext context) {
    final scale =
    (MediaQuery.of(context).size.height / 850).clamp(0.9, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Technicians"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16 * scale,
              16,
              12 * scale,
            ),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search technicians...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                SizedBox(height: 12 * scale),

                Row(
                  children: [
                    Text(
                      "${technicians.length} Technicians Found",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17 * scale,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                20,
              ),
              itemCount: technicians.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final technician = technicians[index];

                return SizedBox(
                  height: 215,
                  child: UserTechnicianHorizontalCard(
                    name: technician.name,
                    profession: technician.service,
                    imageUrl: technician.profilePic ?? "",
                    rating: technician.avgServiceRating ?? 0,
                    reviewCount: technician.completedJobs ?? 0,
                    isVerified: technician.isVerified,
                    location: technician.address,
                    distance: technician.distanceKm == null
                        ? null
                        : "${technician.distanceKm!.toStringAsFixed(1)} km",
                    onTap: () {
                      // TODO:
                      // Open Technician Profile
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}