import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TechnicianRequestScreen extends StatefulWidget {
  const TechnicianRequestScreen({super.key});

  @override
  State<TechnicianRequestScreen> createState() =>
      _TechnicianRequestScreenState();
}

class _TechnicianRequestScreenState
    extends State<TechnicianRequestScreen> {

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  ///  UPDATE STATUS FUNCTION
  Future<void> _updateStatus(String requestId, String status) async {
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .update({"status": status});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Incoming Requests"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('technicianId', isEqualTo: currentUserId)
            .where('status', isEqualTo: 'pending')
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No requests"));
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['service'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),

                      Text(data['description'] ?? ''),

                      const SizedBox(height: 10),

                      // IMAGE (if exists)
                      if (data['imageUrl'] != null &&
                          data['imageUrl'].toString().isNotEmpty)
                        Container(
                          height: 100,
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Image.network(
                            data['imageUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image),
                          ),
                        ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // ACCEPT
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: () {
                              _updateStatus(doc.id, "accepted");
                            },
                            child: const Text("Accept"),
                          ),

                          const SizedBox(width: 10),

                          // REJECT
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () {
                              _updateStatus(doc.id, "rejected");
                            },
                            child: const Text("Reject"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}