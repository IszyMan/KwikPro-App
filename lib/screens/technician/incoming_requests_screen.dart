import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kwikpro/screens/technician/technician_accepted_jobs_screen.dart';
import 'package:kwikpro/screens/technician/technician_home_screen.dart';
import 'package:kwikpro/screens/technician/technician_main_screen.dart';

class IncomingRequestsScreen extends StatefulWidget {
  final VoidCallback onJobAccepted;

  const IncomingRequestsScreen({super.key, required this.onJobAccepted});

  @override
  State<IncomingRequestsScreen> createState() => _IncomingRequestsScreenState();
}
class _IncomingRequestsScreenState extends State<IncomingRequestsScreen> {
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
                trailing: SizedBox(
                  width: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          print("BUTTON CLICKED");
                          _updateStatus(context, doc.id, "accepted");
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(Icons.check, color: Colors.green),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          print("REJECT CLICKED");
                          _updateStatus(context, doc.id, "rejected");
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(Icons.close, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _updateStatus(BuildContext context, String requestId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({"status": status});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == "accepted" ? "Job accepted ✅" : "Job rejected ❌",
          ),
        ),
      );

      if (status == "accepted") {
        widget.onJobAccepted();
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}