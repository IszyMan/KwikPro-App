import 'package:flutter/material.dart';

import '../screens/user/service_job_request_screen.dart';

class ServiceCard extends StatelessWidget {
  final String service;
  final String? initialLocation;
  final double? initialLat;
  final double? initialLng;

  const ServiceCard({
    super.key,
    required this.service,
    this.initialLat,
    this.initialLng,
    this.initialLocation,
  });

  @override
  Widget build(BuildContext context) {
    final scale =
    (MediaQuery.of(context).size.height / 850).clamp(0.85, 1.0);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceJobRequestScreen(
              service: service,
              initialLocation: initialLocation,
              initialLat: initialLat,
              initialLng: initialLng,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12 * scale,
          vertical: 10 * scale,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42 * scale,
              height: 42 * scale,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getServiceIcon(service),
                color: Colors.blue.shade700,
                size: 22 * scale,
              ),
            ),

            SizedBox(height: 8 * scale),

            Text(
              service,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13 * scale,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getServiceIcon(String service) {
    switch (service.toLowerCase()) {
      case 'electrician':
        return Icons.electrical_services;
      case 'plumber':
        return Icons.plumbing;
      case 'fridge repairer':
        return Icons.kitchen;
      case 'ac repairer':
        return Icons.ac_unit;
      case 'painter':
        return Icons.format_paint;
      case 'generator repairer':
        return Icons.settings;
      default:
        return Icons.miscellaneous_services;
    }
  }
}