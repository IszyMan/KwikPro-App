import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kwikpro/models/technician_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kwikpro/screens/user/active_job_screen.dart';
import 'package:audioplayers/audioplayers.dart';

class TechnicianCard extends StatefulWidget {
  final TechnicianModel technician;
  final double? userLat;
  final double? userLng;
  final String serviceLocationAddress;
  final String issueDescription;
  final String imageUrl;

  const TechnicianCard({
    super.key,
    required this.technician,
    required this.serviceLocationAddress,
    this.userLat,
    this.userLng,
    required this.issueDescription,
    required this.imageUrl,
  });

  @override
  State<TechnicianCard> createState() => _TechnicianCardState();
}

class _TechnicianCardState extends State<TechnicianCard> {
  int countdown = 30;
  bool isCounting = false;
  String lastStatus = "";
  final AudioPlayer audioPlayer = AudioPlayer();

  void startTimer() {
    countdown = 30;
    isCounting = true;

    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 1));
      if (!mounted) return false;

      if (countdown <= 0) {
        isCounting = false;
        return false;
      }

      setState(() {
        countdown--;
      });

      return isCounting;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('userId', isEqualTo: user.uid)
          .where('technicianId', isEqualTo: widget.technician.uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        String status = "none";

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          status = data['status'] ?? "none";

          // Play audio notification when status changes to accepted
          if (status == "accepted" && lastStatus != "accepted") {
            audioPlayer.play(AssetSource('notification.mp3'));
          }

          lastStatus = status;

          // Start countdown for pending
          if (status == "pending" && !isCounting) startTimer();
        }

        return _buildCard(context, status);
      },
    );
  }

  Widget _buildCard(BuildContext context, String status) {
    double distanceInKm = 0;
    String eta = '--';

    if (widget.userLat != null &&
        widget.userLng != null &&
        widget.technician.lat != null &&
        widget.technician.long != null) {
      distanceInKm = Geolocator.distanceBetween(
          widget.userLat!,
          widget.userLng!,
          widget.technician.lat!,
          widget.technician.long!) /
          1000;

      int minutes = ((distanceInKm / 40) * 60).ceil();
      eta = '$minutes min away';
    }

    return Card(
      margin: EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: widget.technician.profilePic != null &&
                  widget.technician.profilePic!.isNotEmpty
                  ? NetworkImage(widget.technician.profilePic!)
                  : null,
              child: widget.technician.profilePic == null ||
                  widget.technician.profilePic!.isEmpty
                  ? Icon(Icons.person)
                  : null,
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.technician.name,
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(widget.technician.service),
                  Text(widget.technician.address,
                      style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16),
                      Text('${distanceInKm.toStringAsFixed(1)} km'),
                      SizedBox(width: 10),
                      Icon(Icons.timer, size: 16),
                      Text(eta),
                    ],
                  ),
                  SizedBox(height: 6),
                  // Status badge
                  Row(
                    children: [
                      if (status == "pending")
                        Chip(
                          label: Text("⏳ Waiting For Technician"),
                          backgroundColor: Colors.blue.shade200,
                        ),
                      if (status == "accepted")
                        Chip(
                          label: Text("✅ Accepted"),
                          backgroundColor: Colors.green.shade200,
                        ),
                      if (status == "rejected")
                        Chip(
                          label: Text("❌ Declined"),
                          backgroundColor: Colors.red.shade200,
                        ),
                      if (status == "cancelled")
                        Chip(
                          label: Text("⚠️ No Reply"),
                          backgroundColor: Colors.orange.shade200,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            _buildButton(context, status),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String status) {
    switch (status) {
      case "pending":
        return ElevatedButton(
          onPressed: null,
          child: Text("Waiting... ${countdown}s"),
        );

      case "accepted":
        return ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ActiveJobScreen(technician: widget.technician),
              ),
            );
          },
          child: Text("View Technician"),
        );

      case "rejected":
        return ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => _sendRequest(context),
          child: Text("Retry"),
        );

      case "cancelled":
        return ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          onPressed: () => _sendRequest(context),
          child: Text("Try Again"),
        );

      default:
        return ElevatedButton(
          onPressed: () => _sendRequest(context),
          child: Text("Request"),
        );
    }
  }

  void _sendRequest(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    startTimer(); // start countdown immediately

    final docRef =
    await FirebaseFirestore.instance.collection('requests').add({
      "userId": user.uid,
      "technicianId": widget.technician.uid,
      "service": widget.technician.service,
      'serviceLocationAddress': widget.serviceLocationAddress,
      "description": widget.issueDescription,
      "imageUrl": widget.imageUrl.isNotEmpty ? widget.imageUrl : null,
      "userLat": widget.userLat,
      "userLng": widget.userLng,
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Request sent")));

    // Auto cancel after 20s
    Future.delayed(Duration(seconds: 30), () async {
      final doc = await docRef.get();
      if (doc.exists && doc['status'] == 'pending') {
        await docRef.update({"status": "cancelled"});
      }
    });
  }
}