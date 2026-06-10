import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kwikpro/models/technician_model.dart';
import 'package:kwikpro/screens/user/review_success_screen.dart';

import '../../services/notification_service.dart';

class RatingReviewScreen extends StatefulWidget {
  final TechnicianModel technician;
  final String requestId;

  const RatingReviewScreen({
    super.key,
    required this.technician,
    required this.requestId,
  });

  @override
  State<RatingReviewScreen> createState() => _RatingReviewScreenState();
}

class _RatingReviewScreenState extends State<RatingReviewScreen> {
  final TextEditingController reviewController = TextEditingController();

  double priceRating = 3;
  double serviceRating = 3;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    double overall = (priceRating + serviceRating) / 2;

    return Scaffold(
      appBar: AppBar(title: const Text("Rate Technician")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: reviewController,
              decoration: const InputDecoration(
                labelText: "Write review",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 20),

            _star("Price", priceRating, (v) {
              setState(() => priceRating = v);
            }),

            _star("Service", serviceRating, (v) {
              setState(() => serviceRating = v);
            }),

            const SizedBox(height: 20),

            Text("Overall: ${overall.toStringAsFixed(1)}"),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: loading ? null : _submit,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit & Complete Job"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _star(String label, double rating, Function(double) onChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Row(
          children: List.generate(5, (i) {
            return IconButton(
              icon: Icon(
                Icons.star,
                color: i < rating ? Colors.amber : Colors.grey,
              ),
              onPressed: () => onChange((i + 1).toDouble()),
            );
          }),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      final overall = (priceRating + serviceRating) / 2;

      // 1. Save review
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(widget.requestId)
          .set({
        "userId": user.uid,
        "technicianId": widget.technician.uid,
        "requestId": widget.requestId,
        "review": reviewController.text.trim(),

        // ratings
        "rating": overall,
        "priceRating": priceRating,
        "serviceRating": serviceRating,

        "createdAt": FieldValue.serverTimestamp(),
      });

      // 2. Complete job
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
        "status": "completed",
        "isActive": false,
        "timeline.completedAt": FieldValue.serverTimestamp(),
      });


      await NotificationService.send(
        recipientId: widget.technician.uid,
        title: "New Review",
        body: "You received a ${overall.toStringAsFixed(1)}★ review",
        requestId: widget.requestId,
        type: "review",
      );

      // 3. Notify technician
      await FirebaseFirestore.instance.collection("notifications").add({
        "recipientId": widget.technician.uid,
        "type": "job_completed",
        "title": "Job Completed",
        "body": "Customer confirmed job completion",
        "requestId": widget.requestId,
        "read": false,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // 4. Update stats
      final techRef = FirebaseFirestore.instance
          .collection('technicians')
          .doc(widget.technician.uid);

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(techRef);

        final data = snap.data() as Map<String, dynamic>;

        double avgRating = (data['avgRating'] ?? 0).toDouble();
        double avgPriceRating =
        (data['avgPriceRating'] ?? 0).toDouble();

        double avgServiceRating =
        (data['avgServiceRating'] ?? 0).toDouble();

        int totalReviews = (data['totalReviews'] ?? 0);

        int completedJobs =
        (data['completedJobs'] ?? 0);

        // new averages
        double newAvgRating =
            ((avgRating * totalReviews) + overall) /
                (totalReviews + 1);

        double newAvgPrice =
            ((avgPriceRating * totalReviews) + priceRating) /
                (totalReviews + 1);

        double newAvgService =
            ((avgServiceRating * totalReviews) + serviceRating) /
                (totalReviews + 1);

        tx.update(techRef, {
          "avgRating": newAvgRating,
          "avgPriceRating": newAvgPrice,
          "avgServiceRating": newAvgService,
          "totalReviews": totalReviews + 1,
          "completedJobs": completedJobs + 1,
        });
      });

      if (!mounted) return;

      setState(() => loading = false);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const ReviewSuccessScreen(),
        ),
      );
    } catch (e) {
      debugPrint("REVIEW ERROR: $e");
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }
}