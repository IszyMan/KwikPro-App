import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// ✅ SOURCE OF TRUTH: reviews collection
  Future<int> _getCompletedJobs() async {
    final snap = await FirebaseFirestore.instance
        .collection('reviews')
        .where('technicianId', isEqualTo: technician.uid)
        .get();

    return snap.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(technician.name)),

      body: FutureBuilder<int>(
        future: _getCompletedJobs(),
        builder: (context, snapshot) {
          final completedJobs = snapshot.data ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== PROFILE IMAGE =====
                CircleAvatar(
                  radius: 40,
                  backgroundImage:
                  (technician.profilePic?.isNotEmpty ?? false)
                      ? NetworkImage(technician.profilePic!)
                      : null,
                  child: (technician.profilePic?.isEmpty ?? true)
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),

                const SizedBox(height: 16),

                // ===== NAME =====
                Text(
                  technician.service,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text("Area of operation: ${technician.address}"),

                const SizedBox(height: 12),

                // ===== COMPLETED JOBS (NEW) =====
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Completed Jobs: $completedJobs",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ===== SKILLS =====
                const Text(
                  "Skills",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 6,
                  children: (technician.skills ?? [])
                      .map((s) => Chip(label: Text(s)))
                      .toList(),
                ),

                const SizedBox(height: 20),

                // ===== REQUEST BUTTON =====
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // trigger request flow later
                    },
                    child: const Text("Request Service"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}