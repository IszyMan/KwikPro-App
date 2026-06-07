import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kwikpro/models/technician_model.dart';
import 'package:kwikpro/screens/user/rating_review_screen.dart';

class ActiveJobScreen extends StatefulWidget {
  final TechnicianModel technician;
  final String requestId;

  const ActiveJobScreen({
    super.key,
    required this.technician,
    required this.requestId,
  });

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Active Job")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('requests')
              .doc(widget.requestId)
              .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final status = data['status'];
              final dialogShown = data['completionDialogShown'] ?? false;

              if (status == "completionRequested" && dialogShown == false) {
                FirebaseFirestore.instance
                    .collection('requests')
                    .doc(widget.requestId)
                    .update({
                  "completionDialogShown": true,
                });

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _showCompletionDialog(context);
                  }
                });
              }

              return _buildUI(status);
            }
        ),
      ),
    );
  }

  Widget _buildUI(String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTechnicianInfo(),
        const SizedBox(height: 20),

        Text(
          "Status: $status",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 20),

        if (status == "accepted")
          const Text("Technician has accepted your request"),

        if (status == "onTheWay")
          const Text("🚗 Technician is on the way"),

        if (status == "arrived")
          const Text("📍 Technician has arrived"),

        if (status == "started")
          const Text("🛠 Job in progress..."),

        if (status == "completed")
          const Text(
            "✅ Job Completed",
            style: TextStyle(color: Colors.green),
          ),
      ],
    );
  }

  Widget _buildTechnicianInfo() {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: widget.technician.profilePic != null
              ? NetworkImage(widget.technician.profilePic!)
              : null,
        ),
        const SizedBox(height: 10),
        Text(
          widget.technician.name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(widget.technician.service),
      ],
    );
  }


  void _showCompletionDialog(BuildContext parentContext) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Job Completed"),
          content: const Text(
              "Has the technician completed the job to your satisfaction?"
          ),
          actions: [
            TextButton(
            onPressed: () async {


                await FirebaseFirestore.instance
                    .collection('requests')
                    .doc(widget.requestId)
                    .update({
                  "status": "completed",
                  "isActive": false,
                });

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RatingReviewScreen(
                      requestId: widget.requestId,
                      technician: widget.technician,
                    ),
                  ),
                );
              },
              child: const Text("Yes"),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(context);

              },
              child: const Text("Report"),
            ),
          ],
        );
      },
    );
  }
}