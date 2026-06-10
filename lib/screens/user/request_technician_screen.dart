import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/technician_model.dart';
import '../../widgets/technician_card.dart';

class RequestTechnicianScreen extends StatefulWidget {
  final TechnicianModel technician;
  final double? userLat;
  final double? userLng;
  final String serviceLocationAddress;
  final String issueDescription;
  final String imageUrl;
  final List<String> selectedSkills;

  const RequestTechnicianScreen({
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
  State<RequestTechnicianScreen> createState() =>
      _RequestTechnicianScreenState();
}

class _RequestTechnicianScreenState extends State<RequestTechnicianScreen> {
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _techStream;

  @override
  void initState() {
    super.initState();

    // ONLY THIS TECHNICIAN STREAM
    _techStream = FirebaseFirestore.instance
        .collection('technicians')
        .doc(widget.technician.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Service"),
        centerTitle: true,
      ),

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _techStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("Technician not found"),
            );
          }

          final data = snapshot.data!.data()!;

          final technician = TechnicianModel.fromMap(data);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                /// ONLY ONE TECHNICIAN CARD
                TechnicianCard(
                  technician: technician,
                  userLat: widget.userLat,
                  userLng: widget.userLng,
                  serviceLocationAddress:
                  widget.serviceLocationAddress,
                  issueDescription: widget.issueDescription,
                  imageUrl: widget.imageUrl,
                  selectedSkills: widget.selectedSkills,
                ),

                const SizedBox(height: 20),

                /// OPTIONAL ACTION BUTTON (if you want request here too)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Back"),
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