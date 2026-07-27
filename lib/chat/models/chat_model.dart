import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final String requestId;

  final String userId;
  final String userName;
  final String? userImage;

  final String technicianId;
  final String technicianName;
  final String? technicianImage;

  final List<dynamic> participants;

  final String lastMessage;
  final String? lastSenderId;
  final String? lastReceiverId;

  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  ChatModel({
    required this.id,
    required this.requestId,
    required this.userId,
    required this.userName,
    required this.technicianId,
    required this.technicianName,
    required this.participants,
    required this.lastMessage,
    this.userImage,
    this.technicianImage,
    this.lastSenderId,
    this.lastReceiverId,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatModel(
      id: doc.id,
      requestId: data["requestId"] ?? "",
      userId: data["userId"] ?? "",
      userName: data["userName"] ?? "",
      userImage: data["userImage"],
      technicianId: data["technicianId"] ?? "",
      technicianName: data["technicianName"] ?? "",
      technicianImage: data["technicianImage"],
      participants: data["participants"] ?? [],
      lastMessage: data["lastMessage"] ?? "",
      lastSenderId: data["lastSenderId"],
      lastReceiverId: data["lastReceiverId"],
      createdAt: data["createdAt"],
      updatedAt: data["updatedAt"],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "requestId": requestId,
      "userId": userId,
      "userName": userName,
      "userImage": userImage,
      "technicianId": technicianId,
      "technicianName": technicianName,
      "technicianImage": technicianImage,
      "participants": participants,
      "lastMessage": lastMessage,
      "lastSenderId": lastSenderId,
      "lastReceiverId": lastReceiverId,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }
}