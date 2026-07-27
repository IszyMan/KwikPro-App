import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/chat_service.dart';

/// =======================================================
/// Chat Provider
/// =======================================================

final chatProvider = Provider<ChatProvider>((ref) {
  return ChatProvider();
});

class ChatProvider {
  // ==========================
  // CHAT LIST
  // ==========================

  Stream<QuerySnapshot> chatList(String userId) {
    return ChatService.chatList(userId);
  }

  // ==========================
  // MESSAGE STREAM
  // ==========================

  Stream<QuerySnapshot> messageStream(String chatId) {
    return ChatService.messageStream(chatId);
  }

  // ==========================
  // UNREAD COUNT
  // ==========================

  Stream<int> unreadCount(
      String chatId,
      String userId,
      ) {
    return ChatService.unreadCount(
      chatId,
      userId,
    );
  }

  // ==========================
  // SEARCH
  // ==========================

  Stream<QuerySnapshot> searchChats(
      String userId,
      String keyword,
      ) {
    return ChatService.searchChats(
      userId,
      keyword,
    );
  }

  // ==========================
  // CREATE CHAT
  // ==========================

  Future<void> createChat({
    required String requestId,
    required String userId,
    required String userName,
    String? userImage,
    required String technicianId,
    required String technicianName,
    String? technicianImage,
  }) {
    return ChatService.createChat(
      requestId: requestId,
      userId: userId,
      userName: userName,
      userImage: userImage,
      technicianId: technicianId,
      technicianName: technicianName,
      technicianImage: technicianImage,
    );
  }

  // ==========================
  // SEND MESSAGE
  // ==========================

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) {
    return ChatService.sendMessage(
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
    );
  }

  // ==========================
  // MARK AS READ
  // ==========================

  Future<void> markAsRead({
    required String chatId,
    required String userId,
  }) {
    return ChatService.markAsRead(
      chatId: chatId,
      userId: userId,
    );
  }

  // ==========================
  // TYPING
  // ==========================

  Future<void> typing({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) {
    return ChatService.typing(
      chatId: chatId,
      userId: userId,
      isTyping: isTyping,
    );
  }

  // ==========================
  // LAST SEEN
  // ==========================

  Future<void> lastSeen(String userId) {
    return ChatService.lastSeen(userId);
  }
}