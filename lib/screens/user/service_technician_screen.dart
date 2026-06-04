import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/technician_model.dart';
import '../../widgets/technician_card.dart';
import 'package:geolocator/geolocator.dart';


class ServiceTechniciansScreen extends StatelessWidget {
  final String service;
  final double? userLat;
  final double? userLng;

  double _calculateDistance(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  const ServiceTechniciansScreen({super.key, required this.service, this.userLat, this.userLng});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verified KwikPro ${service}s'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('technicians')
            .where('isOnline', isEqualTo: true)
            .where('isVerified', isEqualTo: true)
            .where('isSuspended', isEqualTo: false)
            .where('service', isEqualTo: service) // KEY FILTER
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No $service available"));
          }

          final allDocs = snapshot.data!.docs;

          final filteredDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            if (userLat == null || userLng == null) return true;

            final techLat = data['lat'];
            final techLng = data['lng'];

            if (techLat == null || techLng == null) return false;

            final distance = Geolocator.distanceBetween(
              userLat!,
              userLng!,
              techLat.toDouble(),
              techLng.toDouble(),
            );

            return distance <= 10000; // 10km radius
          }).toList();

          return ListView.builder(
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final data = filteredDocs[index].data() as Map<String, dynamic>;

              return TechnicianCard(
                technician: TechnicianModel.fromMap(data),
                serviceLocationAddress: "",
                issueDescription: "",
                selectedSkills: [],
                imageUrl: "",
              );
            },
          );
        },
      ),
    );
  }
}