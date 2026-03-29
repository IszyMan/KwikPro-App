import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class IncomingRequestsScreen extends StatelessWidget {
  const IncomingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final technicianId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('technicianId', isEqualTo: technicianId)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        final requests = snapshot.data!.docs;

        if (requests.isEmpty) {
          return Center(child: Text("No incoming requests"));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final doc = requests[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: EdgeInsets.all(10),
              child: ListTile(
                title: Text(data['service']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //  Description
                    if (data['description'] != null)
                      Text(data['description']),

                    //  Service Location Address
                    if (data['serviceLocationAddress'] != null &&
                        data['serviceLocationAddress'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text('📍 ${data['serviceLocationAddress']}',
                                style: TextStyle(color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check, color: Colors.green),
                      onPressed: () =>
                          _updateStatus(doc.id, "accepted"),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () =>
                          _updateStatus(doc.id, "rejected"),
                    ),
                  ],
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