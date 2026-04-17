import 'package:flutter/material.dart';

import '../../models/technician_model.dart';


class ViewTechnicianProfileScreen extends StatelessWidget {
  final TechnicianModel technician;
  final double? userLat;
  final double? userLng;
  final String serviceLocationAddress;
  final String issueDescription;
  final String imageUrl;
  final List<String> selectedSkills;

  const ViewTechnicianProfileScreen({
    super.key,
    required this.technician,
    required this.userLat,
    required this.userLng,
    required this.serviceLocationAddress,
    required this.issueDescription,
    required this.imageUrl,
    required this.selectedSkills,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(technician.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: (technician.profilePic?.isNotEmpty ?? false)
                  ? NetworkImage(technician.profilePic!)
                  : null,
              child: (technician.profilePic?.isEmpty ?? true)
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),

            const SizedBox(height: 16),

            Text(technician.service,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 8),

            Text(technician.address),

            const SizedBox(height: 12),

            const Text(
              "Skills",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            Wrap(
              spacing: 6,
              children: (technician.skills ?? [])
                  .map((s) => Chip(label: Text(s)))
                  .toList(),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                // reuse same request logic pattern
                Navigator.pop(context);

                // or trigger request flow here later
              },
              child: const Text("Request Service"),
            ),
          ],
        ),
      ),
    );
  }
}