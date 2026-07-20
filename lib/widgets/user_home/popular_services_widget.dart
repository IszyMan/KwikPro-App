import 'package:flutter/material.dart';

import '../../widgets/service_card.dart';
import 'section_header.dart';
import '../../screens/user/all_services_screen.dart';

class PopularServicesWidget extends StatelessWidget {
  final List<String> services;
  final String? location;
  final double? lat;
  final double? lng;
  final VoidCallback? onSeeAll;

  const PopularServicesWidget({
    super.key,
    required this.services,
    this.location,
    this.lat,
    this.lng,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final displayServices = services.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Popular Services",
          subtitle: "Find professionals near you",
          onSeeAll: onSeeAll ??
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AllServicesScreen(
                      services: services,
                      location: location,
                      lat: lat,
                      lng: lng,
                    ),
                  ),
                );
              },
        ),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayServices.length,
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,

              // Smaller cards than before
              childAspectRatio: 1.45,
            ),
            itemBuilder: (context, index) {
              return ServiceCard(
                service: displayServices[index],
                initialLocation: location,
                initialLat: lat,
                initialLng: lng,
              );
            },
          ),
        ),
      ],
    );
  }
}