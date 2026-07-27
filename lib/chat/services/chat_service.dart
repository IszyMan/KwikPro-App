import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference get _chatCollection =>
      _db.collection('chats');

  static DocumentReference chat(String chatId) =>
      _chatCollection.doc(chatId);

  static CollectionReference messages(String chatId) =>
      chat(chatId).collection('messages');


  static Future<void> createChat({
    required String requestId,
    required String userId,
    required String userName,
    String? userImage,
    required String technicianId,
    required String technicianName,
    String? technicianImage,
  }) async {

    final doc = chat(requestId);

    final existing = await doc.get();

    if (existing.exists) return;

    await doc.set({

      "requestId": requestId,

      "userId": userId,
      "userName": userName,
      "userImage": userImage,

      "technicianId": technicianId,
      "technicianName": technicianName,
      "technicianImage": technicianImage,

      "participants": [
        userId,
        technicianId,
      ],

      "lastMessage": "",

      "lastSenderId": null,
      "lastReceiverId": null,

      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),

    });
  }


  static Future<void> sendMessage({

    required String chatId,

    required String senderId,

    required String receiverId,

    required String text,

  }) async {

    if (text.trim().isEmpty) return;

    final message = {

      "senderId": senderId,

      "receiverId": receiverId,

      "text": text.trim(),

      "read": false,

      "timestamp": FieldValue.serverTimestamp(),

    };

    await messages(chatId).add(message);

    await chat(chatId).update({

      "lastMessage": text,

      "lastSenderId": senderId,

      "lastReceiverId": receiverId,

      "updatedAt": FieldValue.serverTimestamp(),

    });

  }


  static Stream<QuerySnapshot> messageStream(String chatId) {

    return messages(chatId)
        .orderBy(
      "timestamp",
      descending: true,
    )
        .snapshots();

  }


  static Stream<QuerySnapshot> chatList(
      String userId,
      ) {

    return _chatCollection
        .where(
      "participants",
      arrayContains: userId,
    )
        .orderBy(
      "updatedAt",
      descending: true,
    )
        .snapshots();

  }


  static Stream<int> unreadCount(
      String chatId,
      String userId,
      ) {
    return messages(chatId)
        .where(
      "receiverId",
      isEqualTo: userId,
    )
        .where(
      "read",
      isEqualTo: false,
    )
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  static Future<void> markAsRead({
    required String chatId,
    required String userId,
  }) async {
    final unread = await messages(chatId)
        .where(
      "receiverId",
      isEqualTo: userId,
    )
        .where(
      "read",
      isEqualTo: false,
    )
        .get();

    final batch = _db.batch();

    for (final doc in unread.docs) {
      batch.update(doc.reference, {
        "read": true,
      });
    }

    await batch.commit();
  }


  static Stream<QuerySnapshot> searchChats(
      String userId,
      String keyword,
      ) {
    return _chatCollection
        .where(
      "participants",
      arrayContains: userId,
    )
        .orderBy("updatedAt", descending: true)
        .snapshots();
  }

  static Future<void> typing({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    await chat(chatId).set({
      "typing": {
        userId: isTyping,
      }
    }, SetOptions(merge: true));
  }

  static Future<void> lastSeen(
      String userId,
      ) async {
    await _db
        .collection("users")
        .doc(userId)
        .set({
      "lastSeen": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }



}



