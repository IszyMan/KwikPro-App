import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TechnicianNotificationScreen extends StatefulWidget {
  const TechnicianNotificationScreen({super.key});

  @override
  State<TechnicianNotificationScreen> createState() =>
      _TechnicianNotificationScreenState();
}

class _TechnicianNotificationScreenState
    extends State<TechnicianNotificationScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
  }


  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "";

    return DateFormat(
      "dd MMM yyyy • hh:mm a",
    ).format(timestamp.toDate());
  }

  IconData getNotificationIcon(String type) {
    switch (type) {
      case "job_request":
        return Icons.work;

      case "job_accepted":
        return Icons.check_circle;

      case "job_rejected":
        return Icons.cancel;

      case "job_completed":
        return Icons.task_alt;

      case "review":
        return Icons.star;

      case "issue":
        return Icons.report_problem;

      case "payment":
        return Icons.account_balance_wallet;

      case "verification":
        return Icons.verified;

      default:
        return Icons.notifications;
    }
  }

  Color getNotificationColor(String type) {
    switch (type) {
      case "job_request":
        return Colors.blue;

      case "job_accepted":
        return Colors.green;

      case "job_rejected":
        return Colors.red;

      case "job_completed":
        return Colors.green;

      case "review":
        return Colors.amber;

      case "issue":
        return Colors.orange;

      case "payment":
        return Colors.green;

      case "verification":
        return Colors.blue;

      default:
        return Colors.grey;
    }
  }

  Future<void> _deleteNotification(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where(
            'recipientId',
            isEqualTo: uid,
          ).orderBy(
            'createdAt',
            descending: true,
          ).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (!snapshot.hasData ||
                snapshot.data!.docs.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(
                    Icons.notifications_off,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: Text(
                      "No notifications yet",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              );
            }

            final notifications = snapshot.data!.docs;

            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final doc = notifications[index];

                final data =
                doc.data() as Map<String, dynamic>;

                final title =
                    data['title'] ?? "Notification";

                final body =
                    data['body'] ?? "";

                final type =
                    data['type'] ?? "general";

                final read =
                    data['read'] ?? false;

                final rawTimestamp = data['createdAt'];

                final DateTime date;

                if (rawTimestamp is Timestamp) {
                  date = rawTimestamp.toDate();
                } else if (rawTimestamp is DateTime) {
                  date = rawTimestamp;
                } else {
                  date = DateTime.fromMillisecondsSinceEpoch(0);
                }

                return Dismissible(
                  key: Key(doc.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding:
                    const EdgeInsets.only(right: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  direction:
                  DismissDirection.endToStart,
                  onDismissed: (_) async {
                    await _deleteNotification(doc.id);
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    elevation: read ? 1 : 4,
                    child: ListTile(
                      onTap: () async {
                        // MARK ONLY THIS NOTIFICATION AS READ
                        await FirebaseFirestore.instance
                            .collection('notifications')
                            .doc(doc.id)
                            .update({
                          'read': true,
                        });

                        // OPTIONAL: navigate based on type
                        if (type == "job_request" && data['requestId'] != null) {
                          // Navigator.push(...)
                        }
                      },

                      leading: CircleAvatar(
                        backgroundColor:
                        getNotificationColor(type).withOpacity(0.15),
                        child: Icon(
                          getNotificationIcon(type),
                          color: getNotificationColor(type),
                        ),
                      ),

                      title: Text(
                        title,
                        style: TextStyle(
                          fontWeight: read ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),

                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(body),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat("dd MMM yyyy • hh:mm a").format(date),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      trailing: read
                          ? null
                          : const Icon(Icons.circle, size: 10, color: Colors.blue),
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