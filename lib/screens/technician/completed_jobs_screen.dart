import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CompletedJobsScreen extends StatelessWidget {
  const CompletedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final technicianId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('technicianId', isEqualTo: technicianId)
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        final jobs = snapshot.data!.docs;

        if (jobs.isEmpty) {
          return Center(child: Text("No completed jobs yet"));
        }

        return ListView.builder(
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final data =
            jobs[index].data() as Map<String, dynamic>;

            return ListTile(
              title: Text(data['service']),
              subtitle: Text("Completed"),
            );
          },
        );
      },
    );
  }
}