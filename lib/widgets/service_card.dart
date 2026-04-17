import 'package:flutter/material.dart';

import '../screens/user/service_technician_screen.dart';

class ServiceCard extends StatelessWidget {
  final String service;

  const ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ServiceTechniciansScreen(service: service),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // 🔹 ICON
            Icon(
              _getServiceIcon(service),
              size: 32,
              color: Colors.blueGrey,
            ),

            const SizedBox(height: 10),

            // 🔹 TEXT
            Text(
              '${service}s ',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
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