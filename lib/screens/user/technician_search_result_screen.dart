import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kwikpro/models/technician_model.dart';
import 'package:kwikpro/widgets/technician_card.dart';

class TechnicianSearchResultsScreen extends StatefulWidget {
  final String? service;
  final double? userLat;
  final double? userLng;
  final String serviceLocationAddress;
  final String issueDescription;
  final String imageUrl;
  final List<String> selectedSkills;

  const TechnicianSearchResultsScreen({
    super.key,
    required this.service,
    required this.userLat,
    required this.userLng,
    required this.serviceLocationAddress,
    required this.issueDescription,
    required this.imageUrl,
    required this.selectedSkills,
  });

  @override
  State<TechnicianSearchResultsScreen> createState() =>
      _TechnicianSearchResultsScreenState();
}

class _TechnicianSearchResultsScreenState
    extends State<TechnicianSearchResultsScreen> {
  @override
  Widget build(BuildContext context) {

    Query query = FirebaseFirestore.instance
        .collection('technicians')
        .where('isOnline', isEqualTo: true)
        .where('isVerified', isEqualTo: true)
        .where('isSuspended', isEqualTo: false)
        .where('service', isEqualTo: widget.service);

    if (widget.selectedSkills.isNotEmpty) {
      query = query.where(
        'skills',
        arrayContainsAny: widget.selectedSkills,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("${widget.service}s available near you")),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          final nearby = docs.map((d) {
            return TechnicianModel.fromMap(
              d.data() as Map<String, dynamic>,
            );
          }).where((tech) {
            if (tech.lat == null || tech.long == null) return false;
            if (widget.userLat == null || widget.userLng == null) return false;

            final dist = Geolocator.distanceBetween(
              widget.userLat!,
              widget.userLng!,
              tech.lat!,
              tech.long!,
            );


            if (dist / 1000 > 10) return false;

            if (widget.selectedSkills.isNotEmpty) {
              return widget.selectedSkills
                  .every((skill) => tech.skills!.contains(skill));
            }

            return true;

          }).toList();

          if (nearby.isEmpty) {
            return const Center(
              child: Text("No nearby technicians found"),
            );
          }

          return ListView.builder(
            itemCount: nearby.length,
            itemBuilder: (context, index) {
              return TechnicianCard(
                technician: nearby[index],
                userLat: widget.userLat,
                userLng: widget.userLng,
                serviceLocationAddress: widget.serviceLocationAddress,
                issueDescription: widget.issueDescription,
                imageUrl: widget.imageUrl,
                selectedSkills: widget.selectedSkills,
              );
            },
          );
        },
      ),
    );
  }
}