import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TechnicianJobsScreen extends StatelessWidget {
  const TechnicianJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final techId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('technicianId', isEqualTo: techId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        final pending = docs.where((d) => d['status'] == "pending").toList();
        final active = docs.where((d) => d['status'] != "pending" && d['status'] != "completed").toList();

        return ListView(
          children: [
            _section("Incoming Requests", pending, context),
            _section("Active Jobs", active, context),
          ],
        );
      },
    );
  }

  Widget _section(String title, List<QueryDocumentSnapshot> docs, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),

        ...docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'];

          return Card(
            elevation: 3,
            margin: const EdgeInsets.all(14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // SERVICE
                  Text(
                    data['service'] ?? "",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // STATUS
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "Status: $status",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ACTIONS
                  if (status == "pending")
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                _update(doc.id, "accepted", data),
                            child: const Text("Accept"),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () =>
                                _update(doc.id, "rejected", data),
                            child: const Text("Reject"),
                          ),
                        ),
                      ],
                    ),

                  if (status == "accepted")
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            _update(doc.id, "onTheWay", data),
                        child: const Text("Go On The Way"),
                      ),
                    ),

                  if (status == "onTheWay")
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            _update(doc.id, "arrived", data),
                        child: const Text("Arrived"),
                      ),
                    ),

                  if (status == "arrived")
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _showPriceDialog(context, doc.id, data);
                        },
                        child: const Text("Start Job"),
                      ),
                    ),

                  if (status == "inProgress")
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _update(
                          doc.id,
                          "completionRequested",
                          data,
                        ),
                        child: const Text("Request Completion"),
                      ),
                    ),

                  if (status == "completionRequested")
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          "Waiting for user confirmation...",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // ================= PRICE + START JOB =================

  void _showPriceDialog(BuildContext context, String id, Map data) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Set Price"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Enter price"),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Start Job"),
            onPressed: () async {
              await FirebaseFirestore.instance.collection("requests").doc(id).update({
                "status": "inProgress",
                "price": double.tryParse(controller.text) ?? 0,
                "timeline.startedAt": FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ================= UPDATE + NOTIFICATIONS =================

  Future<void> _update(String id, String status, Map data) async {
    await FirebaseFirestore.instance.collection("requests").doc(id).update({
      "status": status,
    });

    // TODO: call notification service here
  }
}