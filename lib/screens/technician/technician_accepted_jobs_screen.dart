import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_button.dart';
import '../../core/app_card.dart';

class TechnicianActiveJobsScreen extends StatefulWidget {
  const TechnicianActiveJobsScreen({super.key});

  @override
  State<TechnicianActiveJobsScreen> createState() =>
      _TechnicianActiveJobsScreenState();
}

class _TechnicianActiveJobsScreenState
    extends State<TechnicianActiveJobsScreen> {
  @override
  Widget build(BuildContext context) {
    final technicianId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('technicianId', isEqualTo: technicianId)
          .where('status', whereIn: ['accepted', 'started']) // include started jobs
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());

        final jobs = snapshot.data!.docs;

        if (jobs.isEmpty) {
          return Center(child: Text("No active jobs"));
        }

        return ListView.builder(
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final doc = jobs[index];
            final data = doc.data() as Map<String, dynamic>;
            final jobId = doc.id;
            final status = data['status'];

            return AppCard(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['service'] ?? "No service",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['description'] ?? "No description",
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          data['serviceLocationAddress'] ?? "No address",
                          style:
                          TextStyle(fontSize: 14, color: Colors.grey[700]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Show feedback if started, else show button
                  status == 'started'
                      ? Container(
                    padding: EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          "Job started",
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                      : AppButton(
                    text: "Start Job",
                    color: Colors.green,
                    onPressed: () => _startJob(jobId),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _startJob(String jobId) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(jobId)
          .update({"status": "started"});
      setState(() {}); // triggers rebuild, card now shows "Job started"
    } catch (e) {
      print("Error starting job: $e");
    }
  }
}