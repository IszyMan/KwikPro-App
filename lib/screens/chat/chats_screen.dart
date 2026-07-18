import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'conversation_screen.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("chats")
            .where("participants", arrayContains: myId)
            .orderBy("updatedAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return const Center(
              child: Text("No conversations yet"),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {

              final data =
              chats[index].data() as Map<String, dynamic>;

              final isTechnician =
                  data["technicianId"] == myId;

              final otherId = isTechnician
                  ? data["userId"]
                  : data["technicianId"];

              final otherName = isTechnician
                  ? data["userName"]
                  : data["technicianName"];

              final otherImage = isTechnician
                  ? data["userImage"]
                  : data["technicianImage"];

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("chats")
                    .doc(chats[index].id)
                    .collection("messages")
                    .where("receiverId", isEqualTo: myId)
                    .where("read", isEqualTo: false)
                    .snapshots(),
                builder: (context, unreadSnapshot) {

                  final unread =
                      unreadSnapshot.data?.docs.length ?? 0;

                  return ListTile(

                    leading: CircleAvatar(
                      radius: 24,
                      backgroundImage:
                      (otherImage != null &&
                          otherImage.toString().isNotEmpty)
                          ? NetworkImage(otherImage)
                          : null,
                      child:
                      (otherImage == null ||
                          otherImage.toString().isEmpty)
                          ? const Icon(Icons.person)
                          : null,
                    ),

                    title: Text(
                      otherName ?? "Unknown",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    subtitle: Text(
                      data["lastMessage"] ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    trailing: unread > 0
                        ? CircleAvatar(
                      radius: 11,
                      backgroundColor: Colors.red,
                      child: Text(
                        unread > 99
                            ? "99+"
                            : "$unread",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    )
                        : null,

                    onTap: () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ConversationScreen(
                            requestId: chats[index].id,
                            otherUserId: otherId,
                            otherUserName: otherName ?? "",
                            otherUserImage: otherImage,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}