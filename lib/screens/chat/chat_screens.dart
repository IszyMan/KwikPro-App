import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String requestId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserImage;

  const ChatScreen({
    super.key,
    required this.requestId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserImage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();

  String get chatId => widget.requestId;
  String get userId => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    markMessagesRead();
    _initChat();
  }


  Future<void> _initChat() async {
    final chatRef =
    FirebaseFirestore.instance.collection("chats").doc(chatId);

    final doc = await chatRef.get();

    if (!doc.exists) {
      await chatRef.set({
        "participants": [userId, widget.otherUserId],
        "lastMessage": "",
        "updatedAt": FieldValue.serverTimestamp(),
        "requestId": chatId,
        "createdAt": FieldValue.serverTimestamp(),

        "lastSenderId": null,
        "lastReceiverId": null, // optional but useful
      });
    }
  }

  Future<void> markMessagesRead() async {
    final unread = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isEqualTo: widget.otherUserId)
        .where('receiverId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    for (final doc in unread.docs) {
      await doc.reference.update({'read': true});
    }
  }


  Future<void> sendMessage() async {
    final text = controller.text.trim();

    if (text.isEmpty) return;

    final chatRef =
    FirebaseFirestore.instance.collection("chats").doc(chatId);

    final messageRef = chatRef.collection("messages");

    try {
      // Clear input immediately for better UX
      controller.clear();

      final messageData = {
        "text": text,
        "senderId": userId,
        "receiverId": widget.otherUserId,
        "timestamp": FieldValue.serverTimestamp(),
        "read": false,
      };

      await messageRef.add(messageData);

      await chatRef.set({
        "lastMessage": text,
        "updatedAt": FieldValue.serverTimestamp(),
        "lastSenderId": userId,
        "lastReceiverId": widget.otherUserId,
      }, SetOptions(merge: true));
    } catch (e) {
      print("SEND ERROR: $e");

      // optional: restore text if send fails
      controller.text = text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.otherUserName)),

      body: Column(
        children: [
          /// ================= MESSAGES =================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("chats")
                  .doc(chatId)
                  .collection("messages")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages yet"));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data =
                    messages[index].data() as Map<String, dynamic>;

                    final isMe = data["senderId"] == userId;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.green.shade200
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(data["text"] ?? ""),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// ================= INPUT =================
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onSubmitted: (_) => sendMessage(),
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration(
                      hintText: "Type message...",
                    ),
                  ),
                ),
                IconButton(
                  onPressed: sendMessage,
                  icon: const Icon(Icons.send),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}