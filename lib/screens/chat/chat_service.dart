import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  ///  STREAM: unread count
  static Stream<int> unreadCountStream(String chatId, String userId) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// MARK AS READ (MOVE FROM UI TO HERE)
  static Future<void> markAsRead(String chatId, String userId) async {
    final ref = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages');

    final unread = await ref
        .where('receiverId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
  }
}