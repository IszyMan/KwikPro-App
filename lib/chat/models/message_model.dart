import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;

  final String senderId;
  final String receiverId;

  final String text;

  final bool read;

  final Timestamp? timestamp;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.read,
    this.timestamp,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MessageModel(
      id: doc.id,
      senderId: data["senderId"] ?? "",
      receiverId: data["receiverId"] ?? "",
      text: data["text"] ?? "",
      read: data["read"] ?? false,
      timestamp: data["timestamp"],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "senderId": senderId,
      "receiverId": receiverId,
      "text": text,
      "read": read,
      "timestamp": timestamp,
    };
  }
}