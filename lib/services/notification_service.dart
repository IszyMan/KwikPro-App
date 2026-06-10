import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final _db = FirebaseFirestore.instance;


  static Future<void> send({
    required String recipientId,
    required String title,
    required String body,
    String? requestId,
    String type = "general",
  }) async {
    await _db.collection("notifications").add({
      "recipientId": recipientId,
      "title": title,
      "body": body,
      "type": type,
      "requestId": requestId,
      "read": false,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }


  static Future<void> jobAccepted({
    required String userId,
    required String requestId,
  }) async {
    await send(
      recipientId: userId,
      title: "Job Accepted",
      body: "A technician has accepted your request",
      requestId: requestId,
      type: "job_accepted",
    );
  }

  static Future<void> jobRejected({
    required String userId,
    required String requestId,
  }) async {
    await send(
      recipientId: userId,
      title: "Job Rejected",
      body: "Your request was declined",
      requestId: requestId,
      type: "job_rejected",
    );
  }

  static Future<void> technicianOnTheWay({
    required String userId,
    required String service,
    required String requestId,
  }) async {
    await send(
      recipientId: userId,
      title: "Technician on the way",
      body: "Your $service technician is on the way",
      requestId: requestId,
      type: "on_the_way",
    );
  }

  static Future<void> jobStarted({
    required String userId,
    required String service,
    required String requestId,
  }) async {
    await send(
      recipientId: userId,
      title: "$service Started",
      body: "Your technician has started the job",
      requestId: requestId,
      type: "job_started",
    );
  }

  static Future<void> jobCompleted({
    required String userId,
    required String service,
    required String requestId,
  }) async {
    await send(
      recipientId: userId,
      title: "Job Completed",
      body: "Your $service job has been completed",
      requestId: requestId,
      type: "job_completed",
    );
  }



  static Future<void> newJobRequest({
    required String technicianId,
    required String service,
    required String requestId,
  }) async {
    await send(
      recipientId: technicianId,
      title: "New Job Request",
      body: "New $service job available near you",
      requestId: requestId,
      type: "new_job",
    );
  }

  static Future<void> appointmentScheduled({
    required String technicianId,
    required String service,
    required String requestId,
  }) async {
    await send(
      recipientId: technicianId,
      title: "New Appointment",
      body: "$service appointment has been scheduled",
      requestId: requestId,
      type: "appointment",
    );
  }



  static Future<void> saveFcmToken({
    required String collection,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance
        .collection(collection)
        .doc(user.uid)
        .update({
      "fcmToken": token,
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      FirebaseFirestore.instance
          .collection(collection)
          .doc(user.uid)
          .update({
        "fcmToken": newToken,
      });
    });
  }


  static void setupForegroundNotifications(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;

      if (notification == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notification.title ?? "New notification"),
        ),
      );
    });
  }
}