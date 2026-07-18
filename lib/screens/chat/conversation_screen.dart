import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_colors.dart';

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
  final TextEditingController _controller =
  TextEditingController();

  final ScrollController _scrollController =
  ScrollController();

  bool _isTyping = false;

  String get chatId => widget.requestId;

  String get currentUserId =>
      FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();

    _initializeChat();

    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  Future<void> _initializeChat() async {
    final chatRef = FirebaseFirestore.instance
        .collection("chats")
        .doc(chatId);

    final doc = await chatRef.get();

    if (!doc.exists) {
      await chatRef.set({
        "requestId": chatId,
        "participants": [
          currentUserId,
          widget.otherUserId,
        ],
        "createdAt":
        FieldValue.serverTimestamp(),
        "updatedAt":
        FieldValue.serverTimestamp(),
        "lastMessage": "",
        "lastSenderId": null,
        "lastReceiverId": null,
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    final unread = await FirebaseFirestore.instance
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .where(
      "senderId",
      isEqualTo: widget.otherUserId,
    )
        .where(
      "receiverId",
      isEqualTo: currentUserId,
    )
        .where(
      "read",
      isEqualTo: false,
    )
        .get();

    for (final doc in unread.docs) {
      await doc.reference.update({
        "read": true,
      });
    }
  }

  Future<void> _setTyping(bool typing) async {
    await FirebaseFirestore.instance
        .collection("chats")
        .doc(chatId)
        .set({
      "typing_$currentUserId": typing,
    }, SetOptions(merge: true));
  }

  Future<void> _stopTyping() async {
    _isTyping = false;
    await _setTyping(false);
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();

    if (text.isEmpty) return;

    final chatRef = FirebaseFirestore.instance
        .collection("chats")
        .doc(chatId);

    final messageRef =
    chatRef.collection("messages");

    _controller.clear();
    await _stopTyping();

    await messageRef.add({
      "text": text,
      "senderId": currentUserId,
      "receiverId": widget.otherUserId,
      "timestamp":
      FieldValue.serverTimestamp(),
      "read": false,
    });

    await chatRef.set({
      "lastMessage": text,
      "updatedAt":
      FieldValue.serverTimestamp(),
      "lastSenderId": currentUserId,
      "lastReceiverId":
      widget.otherUserId,
    }, SetOptions(merge: true));

    Future.delayed(
      const Duration(milliseconds: 120),
          () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(
              milliseconds: 250,
            ),
            curve: Curves.easeOut,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        elevation: 1,
        titleSpacing: 0,

        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage:
              widget.otherUserImage != null &&
                  widget.otherUserImage!
                      .isNotEmpty
                  ? NetworkImage(
                widget.otherUserImage!,
              )
                  : null,
              child:
              widget.otherUserImage ==
                  null ||
                  widget.otherUserImage!
                      .isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("chats")
                        .doc(chatId)
                        .snapshots(),
                    builder: (context, snapshot) {

                      final data =
                      snapshot.data?.data() as Map<String, dynamic>?;

                      final isTyping =
                          data?["typing_${widget.otherUserId}"] == true;

                      return Text(
                        isTyping ? "Typing..." : "Conversation",
                        style: TextStyle(
                          fontSize: 12,
                          color: isTyping
                              ? Colors.green
                              : Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<
                QuerySnapshot>(
              stream: FirebaseFirestore
                  .instance
                  .collection("chats")
                  .doc(chatId)
                  .collection("messages")
                  .orderBy(
                "timestamp",
                descending: true,
              )
                  .snapshots(),
              builder:
                  (context, snapshot) {
                if (snapshot
                    .connectionState ==
                    ConnectionState
                        .waiting) {
                  return const Center(
                    child:
                    CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs
                        .isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                      children: const [
                        Icon(
                          Icons
                              .chat_bubble_outline,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 20),
                        Text(
                          "No messages yet",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight
                                .bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Start the conversation.",
                        ),
                      ],
                    ),
                  );
                }

                final messages =
                    snapshot.data!.docs;

                WidgetsBinding.instance
                    .addPostFrameCallback(
                      (_) {
                    _markMessagesAsRead();
                  },
                );

                return ListView.builder(
                  controller:
                  _scrollController,
                  reverse: true,
                  padding:
                  const EdgeInsets.only(
                    top: 14,
                    bottom: 12,
                  ),
                  itemCount: messages.length,
                  itemBuilder:(context, index)
                  {
                    final data = messages[index].data()as Map<String, dynamic>;

                    final isMe = data["senderId"] == currentUserId;

                    final Timestamp? ts = data["timestamp"];

                    final time = ts == null
                        ? ""
                        : DateFormat(
                        "h:mm a")
                        .format(
                      ts.toDate(),
                    );

                    return _buildMessageBubble(
                      isMe: isMe,
                      message:
                      data["text"] ?? "",
                      time: time,
                      read:
                      data["read"] ??
                          false,
                    );
                  },
                );
              },
            ),
          ),

          _buildMessageInput(),
        ],
      ),
    );
  }
  Widget _buildMessageBubble({
    required bool isMe,
    required String message,
    required String time,
    required bool read,
  }) {
    return Align(
      alignment:
      isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primary
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(
              isMe ? 18 : 4,
            ),
            bottomRight: Radius.circular(
              isMe ? 4 : 18,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 15,
                  color: isMe
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 6),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe
                        ? Colors.white70
                        : Colors.grey,
                  ),
                ),

                if (isMe) ...[
                  const SizedBox(width: 4),

                  Icon(
                    read
                        ? Icons.done_all
                        : Icons.done,
                    size: 16,
                    color: read
                        ? Colors.lightBlueAccent
                        : Colors.white70,
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          10,
          8,
          10,
          10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.08),
              blurRadius: 8,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                textCapitalization:
                TextCapitalization.sentences,
                textInputAction:
                TextInputAction.newline,
                onChanged: (value) async {
                  if (value.isNotEmpty && !_isTyping) {
                    _isTyping = true;
                    await _setTyping(true);
                  }
                  if (value.isEmpty && _isTyping) {
                    await _stopTyping();
                  }
                },
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding:
                  const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),

            const SizedBox(width: 8),

            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}