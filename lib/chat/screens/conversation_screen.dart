import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/typing_indicator.dart';

class ConversationScreen extends StatefulWidget {
  final String requestId;

  final String otherUserId;

  final String otherUserName;

  final String? otherUserImage;

  const ConversationScreen({
    super.key,
    required this.requestId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserImage,
  });

  @override
  State<ConversationScreen> createState() =>
      _ConversationScreenState();
}

class _ConversationScreenState
    extends State<ConversationScreen> {

  final currentUser =
  FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();

    ChatService.markAsRead(
      chatId: widget.requestId,
      userId: currentUser.uid,
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: Row(
          children: [

            CircleAvatar(
              backgroundImage:
              widget.otherUserImage != null
                  ? NetworkImage(
                widget.otherUserImage!,
              )
                  : null,
              child: widget.otherUserImage == null
                  ? const Icon(Icons.person)
                  : null,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                widget.otherUserName,
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [

          Expanded(
            child: _messages(),
          ),

          const TypingIndicator(
            typing: false,
          ),

          MessageInput(
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _messages() {

    return StreamBuilder<QuerySnapshot>(

      stream: ChatService.messageStream(
        widget.requestId,
      ),

      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(

          reverse: true,

          itemCount: docs.length,

          itemBuilder: (context, index) {

            final data =
            docs[index].data()
            as Map<String, dynamic>;

            final isMe =
                data["senderId"] ==
                    currentUser.uid;

            return MessageBubble(

              text: data["text"] ?? "",

              isMe: isMe,

              isRead:
              data["read"] ?? false,
            );
          },
        );
      },
    );
  }

  void _sendMessage(String text) {

    ChatService.sendMessage(

      chatId: widget.requestId,

      senderId: currentUser.uid,

      receiverId: widget.otherUserId,

      text: text,
    );
  }
}