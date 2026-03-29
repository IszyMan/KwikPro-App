import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TechnicianActiveJobsScreen extends StatelessWidget {
  const TechnicianActiveJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final technicianId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('technicianId', isEqualTo: technicianId)
          .where('status', isEqualTo: 'accepted')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        final jobs = snapshot.data!.docs;

        if (jobs.isEmpty) {
          return Center(child: Text("No accepted jobs"));
        }

        return ListView.builder(
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final doc = jobs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: EdgeInsets.all(10),
              child: ListTile(
                title: Text(data['service']),
                subtitle: Text(data['description']),
                trailing: ElevatedButton(
                  onPressed: () =>
                      _updateStatus(doc.id, "completed"),
                  child: Text("Complete"),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _updateStatus(String requestId, String status) async {
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .update({"status": status});
  }
}