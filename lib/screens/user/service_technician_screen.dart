import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/technician_model.dart';
import '../../widgets/technician_card.dart';


class ServiceTechniciansScreen extends StatelessWidget {
  final String service;

  const ServiceTechniciansScreen({super.key, required this.service});

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
            return Center(
              child: Text("No $service available"),
            );
          }

          final technicians = snapshot.data!.docs;

          return ListView.builder(
            itemCount: technicians.length,
            itemBuilder: (context, index) {
              final data =
              technicians[index].data() as Map<String, dynamic>;

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