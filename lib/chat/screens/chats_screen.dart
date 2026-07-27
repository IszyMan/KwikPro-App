import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/conversation_screen.dart';
import '../services/chat_service.dart';
import '../widgets/chat_tile.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: ChatService.chatList(uid),

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
              chats[index].data()
              as Map<String, dynamic>;

              final isUser =
                  uid == data["userId"];

              final otherId = isUser
                  ? data["technicianId"]
                  : data["userId"];

              final otherName = isUser
                  ? data["technicianName"]
                  : data["userName"];

              final otherImage = isUser
                  ? data["technicianImage"]
                  : data["userImage"];

              return StreamBuilder<int>(
                stream: ChatService.unreadCount(
                  chats[index].id,
                  uid,
                ),

                builder: (context, unreadSnapshot) {

                  final unread =
                      unreadSnapshot.data ?? 0;

                  return ChatTile(

                    name: otherName,

                    image: otherImage,

                    lastMessage:
                    data["lastMessage"] ?? "",

                    time: "",

                    unread: unread,

                    onTap: () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ConversationScreen(
                                requestId:
                                chats[index].id,
                                otherUserId: otherId,
                                otherUserName: otherName,
                                otherUserImage:
                                otherImage,
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