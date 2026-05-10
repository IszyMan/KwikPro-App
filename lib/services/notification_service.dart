import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String requestId,
  }) async {
    await _db.collection("notifications").add({
      "userId": userId,
      "title": title,
      "body": body,
      "requestId": requestId,
      "read": false,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }
}