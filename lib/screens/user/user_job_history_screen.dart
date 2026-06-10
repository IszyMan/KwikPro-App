import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kwikpro/screens/user/view_technician_profile_screen.dart';

import '../../widgets/technician_card.dart';
import '../../models/technician_model.dart';

class UserJobHistoryScreen extends StatefulWidget {
  const UserJobHistoryScreen({super.key});

  @override
  State<UserJobHistoryScreen> createState() =>
      _UserJobHistoryScreenState();
}

class _UserJobHistoryScreenState
    extends State<UserJobHistoryScreen> {
  final user = FirebaseAuth.instance.currentUser;

  final activeStatuses = const [
    "pending",
    "accepted",
    "appointmentAccepted",
    "onTheWay",
    "arrived",
    "inProgress",
    "completionRequested",
  ];

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
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Stream<QuerySnapshot> getJobStream() {
    return FirebaseFirestore.instance
        .collection('requests')
        .where('userId', isEqualTo: user!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// ✅ FIXED ACTIVE JOB STREAM (NO isActive)
  Stream<QuerySnapshot> getActiveJobStream() {
    return FirebaseFirestore.instance
        .collection('requests')
        .where('userId', isEqualTo: user!.uid)
        .where('status', whereIn: activeStatuses)
        .limit(1)
        .snapshots();
  }

  Future<TechnicianModel?> _getTechnician(String id) async {
    final doc = await FirebaseFirestore.instance
        .collection('technicians')
        .doc(id)
        .get();

    if (!doc.exists) return null;
    return TechnicianModel.fromMap(doc.data()!);
  }

  Future<void> _refresh() async {
    setState(() {});
  }

  void bookAgain(Map<String, dynamic> data) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Book Again for ${data['service'] ?? 'service'}",
        ),
      ),
    );
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
        title: const Text("My Job History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _refresh,
        child: StreamBuilder<QuerySnapshot>(
          stream: getJobStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final jobs = snapshot.data!.docs;

            final completedJobs = jobs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              return data['status'] == 'completed';
            }).toList();

            return ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              children: [

                /// ================= ACTIVE JOB (FIXED) =================
                StreamBuilder<QuerySnapshot>(
                  stream: getActiveJobStream(),
                  builder: (context, activeSnap) {
                    if (!activeSnap.hasData ||
                        activeSnap.data!.docs.isEmpty) {
                      return const SizedBox();
                    }

                    final doc = activeSnap.data!.docs.first;
                    final data =
                    doc.data() as Map<String, dynamic>;

                    final techId = data['technicianId'];

                    if (techId == null) return const SizedBox();

                    return FutureBuilder<TechnicianModel?>(
                      future: _getTechnician(techId),
                      builder: (context, techSnap) {
                        if (!techSnap.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                "Active Job",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            TechnicianCard(
                              technician: techSnap.data!,
                              userLat: data['userLat'],
                              userLng: data['userLng'],
                              serviceLocationAddress:
                              data['serviceLocationAddress'] ?? "",
                              issueDescription:
                              data['description'] ?? "",
                              imageUrl: data['imageUrl'] ?? "",
                              selectedSkills: const [],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),

                /// ================= COMPLETED HEADER =================
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    "Completed Jobs",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                /// ================= COMPLETED JOBS =================
                ...completedJobs.map((doc) {
                  final data =
                  doc.data() as Map<String, dynamic>;

                  return Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        /// SERVICE
                        Text(
                          "${data['service']} Job",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 6),

                        /// DESCRIPTION
                        Text(data['description'] ?? ""),

                        const SizedBox(height: 6),

                        /// LOCATION
                        Text(
                          data['serviceLocationAddress'] ?? "",
                          style:
                          const TextStyle(color: Colors.grey),
                        ),

                        const SizedBox(height: 6),

                        /// DATE
                        Text(
                          formatDate(data['createdAt']),
                          style:
                          const TextStyle(color: Colors.grey),
                        ),

                        const SizedBox(height: 10),

                        /// BOOK AGAIN
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final techId = data['technicianId'];

                              final tech = await _getTechnician(techId);

                              if (tech == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Technician not found")),
                                );
                                return;
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ViewTechnicianProfileScreen(
                                    technician: tech,
                                    userLat: data['userLat'],
                                    userLng: data['userLng'],
                                    serviceLocationAddress:
                                    data['serviceLocationAddress'] ?? "",
                                    issueDescription: data['description'] ?? "",
                                    imageUrl: data['imageUrl'] ?? "",
                                    selectedSkills: const [],
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text("Book Again"),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}