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

  double _currentRadius = 20;

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

          final technicians = docs
              .map((d) => TechnicianModel.fromMap(
            d.data() as Map<String, dynamic>,
          ))
              .toList();

          double radius = 20;
          List<TechnicianModel> nearby = [];

          while (nearby.isEmpty && radius <= 100) {
            nearby = technicians.where((tech) {
              if (tech.lat == null || tech.lng == null) return false;

              final distance = Geolocator.distanceBetween(
                widget.userLat!,
                widget.userLng!,
                tech.lat!,
                tech.lng!,
              ) /
                  1000;

              return distance <= radius;
            }).toList();

            if (nearby.isEmpty) {
              if (radius == 20) {
                radius = 40;
              } else if (radius == 40) {
                radius = 75;
              } else if (radius == 75) {
                radius = 100;
              } else {
                break;
              }
            }
          }

          _currentRadius = radius;


          nearby.sort((a, b) {
            final distanceA = Geolocator.distanceBetween(
              widget.userLat!,
              widget.userLng!,
              a.lat!,
              a.lng!,
            );

            final distanceB = Geolocator.distanceBetween(
              widget.userLat!,
              widget.userLng!,
              b.lat!,
              b.lng!,
            );

            return distanceA.compareTo(distanceB);
          });

          if (nearby.isEmpty) {
            return const Center(
              child: Text("No nearby technicians found"),
            );
          }

          return Column(
            children: [

              if (_currentRadius > 20)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Expanded search radius to ${_currentRadius.toInt()} km to find more technicians.",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              Expanded(
                child: ListView.builder(
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}