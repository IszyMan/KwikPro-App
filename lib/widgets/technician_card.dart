import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kwikpro/models/technician_model.dart';
import 'package:geolocator/geolocator.dart';

class TechnicianCard extends StatelessWidget {
  final TechnicianModel technician;
  final double? userLat;
  final double? userLng;
  final String issueDescription;
  final String imageUrl;

  const TechnicianCard({
    super.key,
    required this.technician,
    this.userLat,
    this.userLng,
    required this.issueDescription,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    double distanceInKm = 0;
    String eta = '--';

    if (userLat != null &&
        userLng != null &&
        technician.lat != null &&
        technician.long != null) {
      distanceInKm = Geolocator.distanceBetween(
          userLat!, userLng!, technician.lat!, technician.long!) /
          1000;

      // ETA assuming 40 km/h average speed
      double timeInHours = distanceInKm / 40;
      int minutes = (timeInHours * 60).ceil();
      eta = '$minutes min away';
    }

    return Card(
      margin: EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 25,
              backgroundImage: technician.profilePic != null &&
                  technician.profilePic!.isNotEmpty
                  ? NetworkImage(technician.profilePic!)
                  : null,
              child: (technician.profilePic == null ||
                  technician.profilePic!.isEmpty)
                  ? Icon(Icons.person)
                  : null,
            ),

            SizedBox(width: 15),

            // Technician Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    technician.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(technician.service),
                  SizedBox(height: 4),
                  Text(
                    technician.address,
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('${distanceInKm.toStringAsFixed(1)} km'),
                      SizedBox(width: 15),
                      Icon(Icons.timer, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(eta),
                    ],
                  ),
                ],
              ),
            ),

            // Request Button
            ElevatedButton(
              onPressed: () => _sendRequest(context),
              child: Text("Request"),
            ),
          ],
        ),
      ),
    );
  }

  /// Send technician request
  void _sendRequest(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docRef =
      await FirebaseFirestore.instance.collection('requests').add({
        "userId": user.uid,
        "technicianId": technician.uid,
        "service": technician.service,
        "description": issueDescription,
        "imageUrl": imageUrl.isNotEmpty ? imageUrl : null,
        "userLat": userLat,
        "userLng": userLng,
        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Request sent successfully!")),
      );

      // Auto cancel after 20 seconds if still pending
      Future.delayed(Duration(seconds: 20), () async {
        final doc = await FirebaseFirestore.instance
            .collection('requests')
            .doc(docRef.id)
            .get();

        if (doc.exists && doc['status'] == 'pending') {
          await doc.reference.update({"status": "cancelled"});
        }
      });
    } catch (e) {
      print("Error sending request: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send request")),
      );
    }
  }
}