import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserNotificationScreen extends StatefulWidget {
  const UserNotificationScreen({super.key});

  @override
  State<UserNotificationScreen> createState() =>
      _UserNotificationScreenState();
}

class _UserNotificationScreenState
    extends State<UserNotificationScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> markAsRead(String id) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(id)
        .update({'read': true});
  }

  Future<void> deleteNotification(String id) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(id)
        .delete();
  }

  String formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('dd MMM yyyy • hh:mm a')
          .format(timestamp.toDate());
    }
    return '';
  }

  IconData getIcon(String type) {
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
      case "payment":
        return Icons.account_balance_wallet;
      default:
        return Icons.notifications;
    }
  }

  Color getColor(String type) {
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
      case "payment":
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("No notifications yet"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = data['title'] ?? 'Notification';
              final body = data['body'] ?? '';
              final type = data['type'] ?? 'general';
              final read = data['read'] ?? false;
              final time = data['createdAt'];

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                onDismissed: (_) => deleteNotification(doc.id),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: read ? 1 : 4,
                  child: ListTile(
                    onTap: () async {
                      await markAsRead(doc.id);
                    },

                    leading: CircleAvatar(
                      backgroundColor:
                      getColor(type).withOpacity(0.15),
                      child: Icon(
                        getIcon(type),
                        color: getColor(type),
                      ),
                    ),

                    title: Text(
                      title,
                      style: TextStyle(
                        fontWeight:
                        read ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),

                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(body),
                        const SizedBox(height: 4),
                        Text(
                          formatDate(time),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    trailing: read
                        ? null
                        : const Icon(
                      Icons.circle,
                      size: 10,
                      color: Colors.blue,
                    ),
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