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

  /// Fetch reviews once (optimized)
  Future<Map<String, dynamic>> _getStats() async {
    final snap = await FirebaseFirestore.instance
        .collection('reviews')
        .where('technicianId', isEqualTo: technician.uid)
        .get();

    final docs = snap.docs;
    final count = docs.length;

    if (count == 0) {
      return {
        "completedJobs": 0,
        "avgRating": 0.0,
        "avgPrice": 0.0,
        "avgService": 0.0,
      };
    }

    double totalRating = 0;
    double totalPrice = 0;
    double totalService = 0;

    for (final doc in docs) {
      final data = doc.data();

      totalRating += (data['rating'] ?? 0).toDouble();
      totalPrice += (data['priceRating'] ?? 0).toDouble();
      totalService += (data['serviceRating'] ?? 0).toDouble();
    }

    return {
      "completedJobs": count,
      "avgRating": totalRating / count,
      "avgPrice": totalPrice / count,
      "avgService": totalService / count,
    };
  }

  Widget _statCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(title),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(technician.name)),

      body: FutureBuilder<Map<String, dynamic>>(
        future: _getStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("Failed to load profile"));
          }

          final data = snapshot.data!;
          final completedJobs = data['completedJobs'];
          final avgRating = data['avgRating'];
          final avgPrice = data['avgPrice'];
          final avgService = data['avgService'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// PROFILE IMAGE
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

                /// NAME / SERVICE
                Text(
                  technician.service,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text("Area: ${technician.address}"),

                const SizedBox(height: 16),

                /// STATS GRID
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statChip("Completed Jobs", "$completedJobs", Colors.green),
                    _statChip("Rating", avgRating.toStringAsFixed(1), Colors.blue),
                    _statChip("Price", avgPrice.toStringAsFixed(1), Colors.orange),
                    _statChip("Service", avgService.toStringAsFixed(1), Colors.purple),
                  ],
                ),

                const SizedBox(height: 20),

                /// SKILLS
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

                const SizedBox(height: 24),

                /// REQUEST BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
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


  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}