import 'package:flutter/material.dart';
import 'package:kwikpro/models/technician_model.dart';
import 'package:kwikpro/services/firestore_service.dart';
import 'package:kwikpro/widgets/technician_card.dart';

import '../../models/technician_search_result.dart';

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

  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.service}s available near you"),
      ),
      body: FutureBuilder<TechnicianSearchResult>(
        future: _firestoreService.searchTechnicians(
          service: widget.service!,
          userLat: widget.userLat!,
          userLng: widget.userLng!,
          selectedSkills: widget.selectedSkills,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
              ),
            );
          }

          final result = snapshot.data!;
          final technicians = result.technicians;
          final radius = result.radiusUsed;

          if (technicians.isEmpty) {
            return const Center(
              child: Text(
                "No nearby technicians found",
              ),
            );
          }

          return Column(
            children: [

              if (radius > 20)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Expanded search radius to ${radius.toInt()} km to find more technicians.",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: technicians.length,
                  itemBuilder: (context, index) {
                    return TechnicianCard(
                      technician: technicians[index],
                      userLat: widget.userLat,
                      userLng: widget.userLng,
                      serviceLocationAddress:
                      widget.serviceLocationAddress,
                      issueDescription:
                      widget.issueDescription,
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