import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TechnicianJobHistoryScreen extends StatefulWidget {
  const TechnicianJobHistoryScreen({super.key});

  @override
  State<TechnicianJobHistoryScreen> createState() =>
      _TechnicianJobHistoryScreenState();
}

class _TechnicianJobHistoryScreenState
    extends State<TechnicianJobHistoryScreen> {

  final user = FirebaseAuth.instance.currentUser;

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('dd MMM yyyy, hh:mm a')
        .format(timestamp.toDate());
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// STREAM IS NOW STORED IN STATE
  Stream<QuerySnapshot> getJobStream() {
    return FirebaseFirestore.instance
        .collection('requests')
        .where('technicianId', isEqualTo: user!.uid)
        .where('status', isEqualTo: 'completed')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _refresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("No user found")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Job History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          )
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _refresh,
        child: StreamBuilder<QuerySnapshot>(
          stream: getJobStream(),

          builder: (context, snapshot) {

            /// ERROR
            if (snapshot.hasError) {
              return Center(
                child: Text("Error: ${snapshot.error}"),
              );
            }

            /// LOADING
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final jobs = snapshot.data?.docs ?? [];

            /// EMPTY STATE
            if (jobs.isEmpty) {
              return const Center(
                child: Text("No completed jobs yet"),
              );
            }

            return ListView.builder(
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final data =
                jobs[index].data() as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text("${data['service'] ?? 'Service'} Job"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data['description'] != null)
                          Text(data['description']),
                        const SizedBox(height: 4),
                        Text(
                          "📍 ${data['serviceLocationAddress'] ?? 'No location'}",
                        ),
                        const SizedBox(height: 4),
                        Text(formatDate(data['createdAt'])),
                      ],
                    ),
                    trailing: Text(
                      "COMPLETED",
                      style: TextStyle(
                        color: getStatusColor('completed'),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}