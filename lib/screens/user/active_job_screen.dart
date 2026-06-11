import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kwikpro/models/technician_model.dart';
import 'package:kwikpro/screens/user/rating_review_screen.dart';

import '../chat/chat_screens.dart';
import '../chat/chat_service.dart';

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

  String? _status;

  Future<void> markAsRead() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final messagesRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.requestId)
        .collection('messages');

    final unread = await messagesRef
        .where('receiverId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in unread.docs) {
      batch.update(doc.reference, {
        'read': true,
      });
    }

    await batch.commit();
  }


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

            _status = status; // store for FAB

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

            return _buildUI(status, data);
          },
        ),
      ),
    );
  }


  // ================= UI =================

  Widget _buildUI(String status, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTechnicianInfo(),

        const SizedBox(height: 16),

        // ================= CHAT BUTTON (NEW PLACE) =================
        if ([
          "accepted",
          "appointmentAccepted",
          "onTheWay",
          "arrived",
          "inProgress",
          "completionRequested"
        ].contains(status))
          SizedBox(
            width: double.infinity,
            child: StreamBuilder<int>(
              stream: ChatService.unreadCountStream(
                widget.requestId,
                FirebaseAuth.instance.currentUser!.uid,
              ),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;

                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {


                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          requestId: widget.requestId,
                          otherUserId: widget.technician.uid,
                          otherUserName: widget.technician.name,
                          otherUserImage: widget.technician.profilePic,
                        ),
                      ),

                    );
                    markAsRead();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.chat, size: 24),

                          if (unreadCount > 0)
                            Positioned(
                              right: -8,
                              top: -8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  unreadCount > 99 ? "99+" : "$unreadCount",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      const Text("Chat with Technician"),
                    ],
                  ),
                );
              },
            )
          ),

        const SizedBox(height: 16),

        const Text(
          "Job Progress",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 16),

        _buildProgressTracker(status),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getStatusMessage(status),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
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

  // ================= PROGRESS =================

  int _currentStep(String status) {
    switch (status) {
      case "accepted":
      case "appointmentAccepted":
        return 0;

      case "onTheWay":
        return 1;

      case "arrived":
        return 2;

      case "inProgress":
        return 3;

      case "completionRequested":
      case "completed":
        return 4;

      default:
        return 0;
    }
  }

  Widget _buildProgressTracker(String status) {
    final currentStep = _currentStep(status);

    final steps = [
      "Accepted",
      "On The Way",
      "Arrived",
      "In Progress",
      "Completed",
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final completed = index < currentStep;
        final active = index == currentStep;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Icon(
                  completed
                      ? Icons.check_circle
                      : active
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: completed || active ? Colors.green : Colors.grey,
                ),

                if (index != steps.length - 1)
                  Container(
                    width: 2,
                    height: 6,
                    color: index < currentStep
                        ? Colors.green
                        : Colors.grey.shade300,
                  ),
              ],
            ),

            const SizedBox(width: 12),

            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                steps[index],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                  color: completed || active ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ================= STATUS TEXT =================

  String _getStatusMessage(String status) {
    switch (status) {
      case "accepted":
      case "appointmentAccepted":
        return "Your technician has accepted the job.";

      case "onTheWay":
        return "🚗 Technician is on the way to your location.";

      case "arrived":
        return "📍 Technician has arrived.";

      case "inProgress":
        return "🛠 Work is currently in progress.";

      case "completionRequested":
        return "⏳ Technician marked the work as completed and is awaiting your confirmation.";

      case "completed":
        return "✅ Job completed successfully.";

      default:
        return "Waiting for technician.";
    }
  }



  void _showCompletionDialog(BuildContext parentContext) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Job Completed"),
          content: const Text(
            "Has the technician completed the job to your satisfaction?",
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