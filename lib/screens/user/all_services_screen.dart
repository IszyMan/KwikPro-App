import 'package:flutter/material.dart';

import '../../widgets/service_card.dart';

class AllServicesScreen extends StatelessWidget {
  final List<String> services;
  final String? location;
  final double? lat;
  final double? lng;

  const AllServicesScreen({
    super.key,
    required this.services,
    this.location,
    this.lat,
    this.lng,
  });

  @override
  Widget build(BuildContext context) {
    final scale =
    (MediaQuery.of(context).size.height / 850).clamp(0.9, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Services"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              18 * scale,
              20,
              14 * scale,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.home_repair_service,
                  color: Theme.of(context).primaryColor,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Choose a service to continue",
                    style: TextStyle(
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                20,
              ),
              itemCount: services.length,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.45,
              ),
              itemBuilder: (context, index) {
                return ServiceCard(
                  service: services[index],
                  initialLocation: location,
                  initialLat: lat,
                  initialLng: lng,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}