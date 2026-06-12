import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import '../chat/chat_screens.dart';
import '../chat/chat_service.dart';
import 'completed_jobs_screen.dart';

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

        final incomingInstant = docs.where((d) {

          final map = d.data() as Map<String, dynamic>;

          final type = map['type'] ?? "instant";
          final status = map['status'] ?? "";

          return type == "instant" && status == "pending";

        }).toList();

        final incomingAppointments = docs.where((d) {

          final map = d.data() as Map<String, dynamic>;

          final type = map['type'] ?? "";
          final status = map['status'] ?? "";

          return type == "appointment" &&
              status == "scheduled";

        }).toList();

        final active = docs.where((d) {

          final status = d['status'];

          return [
            "accepted",
            "appointmentAccepted",
            "onTheWay",
            "arrived",
            "inProgress",
            "completionRequested",
          ].contains(status);

        }).toList();

        final completed = docs.where((d) {

          final status = d['status'];

          return status == "completed";

        }).toList()
          ..sort((a, b) {

            final aTime =
                (a['timeline']?['completedAt'] as Timestamp?)?.toDate() ??
                    DateTime(2000);

            final bTime =
                (b['timeline']?['completedAt'] as Timestamp?)?.toDate() ??
                    DateTime(2000);

            return bTime.compareTo(aTime);

          });



        return ListView(
          children: [

            _section(
              "Incoming Requests",
              incomingInstant,
              context,
              techId: techId,
              emptyMessage: "No incoming requests",
            ),

            _section(
              "Incoming Appointments",
              incomingAppointments,
              context,
              techId: techId,
              emptyMessage: "No incoming appointments",
            ),

            if (active.isNotEmpty)
              _section("Active Jobs", active, context, techId: techId,),

            _completedPreviewSection(
              completed,
              context,
            ),
          ],
        );
      },
    );
  }

  Widget _section(
      String title,
      List<QueryDocumentSnapshot> docs,
      BuildContext context, {
        String emptyMessage = "No data",
        required String techId,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),

        if (docs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            child: Center(
              child: Text(
                emptyMessage,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),
            ),
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
                    "${data['service'] ?? ""} needed",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),



                  // LOCATION
                  Text(
                    "📍 ${data['serviceLocationAddress'] ?? "No location"}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // DESCRIPTION
                  if ((data['description'] ?? "").toString().isNotEmpty)
                    Text(
                      "📝 ${data['description']}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),



                  if (data['imageUrl'] != null)
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            backgroundColor: Colors.black,
                            child: InteractiveViewer(
                              child: Image.network(data['imageUrl']),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(top: 10),
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            data['imageUrl'],
                            fit: BoxFit.cover,
                          ),
                        ),
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

                  // ================= CHAT BUTTON (ACTIVE JOBS ONLY) =================
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
                        stream: ChatService.unreadCountStream(doc.id, techId),
                        builder: (context, snapshot) {
                          final unreadCount = snapshot.data ?? 0;

                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              // ensure chat exists before opening
                              await FirebaseFirestore.instance
                                  .collection('chats')
                                  .doc(doc.id)
                                  .set({
                                "requestId": doc.id,
                                "participants": [
                                  data['userId'],
                                  techId,
                                ],
                                "updatedAt": FieldValue.serverTimestamp(),
                              }, SetOptions(merge: true));



                              if (!context.mounted) return;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    requestId: doc.id,
                                    otherUserName: data['userName'] ?? "Customer",
                                    otherUserId: data['userId'],
                                    otherUserImage: data['userImage'],
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(Icons.chat),

                                    if (unreadCount > 0)
                                      Positioned(
                                        right: -10,
                                        top: -10,
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

                                const Text("Chat with Customer"),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 12),

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

                  if (status == "scheduled")
                    Row(
                      children: [

                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _update(
                              doc.id,
                              "appointmentAccepted",
                              data,
                            ),
                            child: const Text("Confirm"),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () => _update(
                              doc.id,
                              "appointmentRejected",
                              data,
                            ),
                            child: const Text("Decline"),
                          ),
                        ),
                      ],
                    ),

                  if (status == "appointmentAccepted")
                    Builder(
                      builder: (_) {
                        final appointmentDate =
                        (data['appointmentDate'] as Timestamp).toDate();

                        final isToday =
                            DateTime.now().day == appointmentDate.day &&
                                DateTime.now().month == appointmentDate.month &&
                                DateTime.now().year == appointmentDate.year;

                        final location = data['jobLocation']?['address'] ??
                            data['serviceLocationAddress'] ??
                            "No location";

                        final time = data['appointmentTime'] ?? "--";

                        final description = data['description'] ?? "No description provided";

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("📌 Job Type: Appointment",
                                  style: const TextStyle(fontWeight: FontWeight.bold)),

                              const SizedBox(height: 6),

                              Text("📝 Description: $description"),

                              const SizedBox(height: 6),

                              Text("📍 Location: $location"),

                              const SizedBox(height: 6),

                              Text("📅 Date: ${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}"),

                              const SizedBox(height: 6),

                              Text("⏰ Time: $time"),

                              const SizedBox(height: 12),

                              if (isToday)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _update(doc.id, "onTheWay", data),
                                    child: const Text("Start Appointment Job"),
                                  ),
                                )
                              else
                                const Text(
                                  "Not today yet",
                                  style: TextStyle(color: Colors.grey),
                                ),
                            ],
                          ),
                        );
                      },
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


  Widget _completedPreviewSection(
      List<QueryDocumentSnapshot> docs,
      BuildContext context,
      ) {

    if (docs.isEmpty) {
      return const SizedBox();
    }

    final latest = docs.first;
    final data = latest.data() as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            "Latest Completed Job",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.green.shade200,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  "${data['service'] ?? ""} needed",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "📍 ${data['serviceLocationAddress'] ?? "No location"}",
                ),

                const SizedBox(height: 6),

                if ((data['description'] ?? "").toString().isNotEmpty)
                  Text(
                    "📝 ${data['description']}",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 8),

                Builder(
                  builder: (_) {

                    final completedAt =
                    (data['timeline']?['completedAt'] as Timestamp?)
                        ?.toDate();

                    return Text(
                      completedAt != null
                          ? "📅 Completed on ${completedAt.day}/${completedAt.month}/${completedAt.year}"
                          : "📅 Completion date unavailable",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 6),

                Text(
                  "✅ Completed",
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const CompletedJobsScreen(),
                        ),
                      );

                    },
                    child: const Text(
                      "View All Completed Jobs",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
    final userId = data['userId'];
    final technicianId = data['technicianId'];
    final service = data['service'] ?? "service";

    // ================= UPDATE REQUEST =================
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(id)
        .update({
      "status": status,

      if (status == "completed") ...{
        "isActive": false,
        "timeline.completedAt": FieldValue.serverTimestamp(),
      }
    });

    print("===== CHAT CREATION =====");
    print("userId: $userId");
    print("techId: $technicianId");

    // ================= CREATE CHAT ROOM (ONLY ONCE) =================
    if (status == "accepted" && data['chatCreated'] != true) {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(id)
          .set({
        "participants": [userId, technicianId],
        "lastMessage": "",
        "updatedAt": FieldValue.serverTimestamp(),
        "requestId": id,
        "chatCreated": true,
      }, SetOptions(merge: true));

      // mark chat created
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(id)
          .update({
        "chatCreated": true,
      });
    }

    // ================= NOTIFICATIONS =================
    switch (status) {


      case "arrived":
        await NotificationService.send(
          recipientId: userId,
          title: "Technician Arrived",
          body: "Your technician has arrived at your location",
          requestId: id,
          type: "arrived",
        );
        break;





    }
  }
}