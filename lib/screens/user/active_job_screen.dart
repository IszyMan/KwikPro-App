import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kwikpro/models/technician_model.dart';

class ActiveJobScreen extends StatefulWidget {
  final TechnicianModel technician;
  final String? requestId;

  const ActiveJobScreen({
    super.key,
    required this.technician,
    required this.requestId,
  });

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Active Job")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTechnicianInfo(),
            SizedBox(height: 20),
            _buildCallTile(),
            _buildMapTile(),
            SizedBox(height: 20),
            Text(
              "You will be notified here when the Technician starts your job. ",
              style: TextStyle(fontSize: 16),
            ),
            Text("Please remember to mark completed when job is done and leave a review", style: TextStyle(color: Colors.blueAccent, fontSize: 20),),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .doc(widget.requestId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final status = data['status'] ?? "unknown";

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    SizedBox(height: 10),
                    if (status == "started")
                      const Text("🛠️ Technician has started the job"),
                    const SizedBox(height: 10),
                    if (status == "started")
                      ElevatedButton(
                        onPressed: isLoading ? null : () => _showRatingDialog(context),
                        child: isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text("Mark as Completed"),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicianInfo() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: widget.technician.profilePic != null
                ? NetworkImage(widget.technician.profilePic!)
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            widget.technician.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(widget.technician.service),
        ],
      ),
    );
  }

  Widget _buildCallTile() {
    return const ListTile(
      leading: Icon(Icons.phone),
      title: Text("Call Technician"),
    );
  }

  Widget _buildMapTile() {
    return const ListTile(
      leading: Icon(Icons.map),
      title: Text("View on Map"),
    );
  }

  /// ================= COMPLETE JOB =================

  void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return RatingDialog(
          technician: widget.technician,
          requestId: widget.requestId!,
          onSubmitStart: () => setState(() => isLoading = true),
          onSubmitEnd: () => setState(() => isLoading = false),
        );
      },
    );
  }
}



class RatingDialog extends StatefulWidget {
  final TechnicianModel technician;
  final String requestId;
  final VoidCallback onSubmitStart;
  final VoidCallback onSubmitEnd;

  const RatingDialog({
    super.key,
    required this.technician,
    required this.requestId,
    required this.onSubmitStart,
    required this.onSubmitEnd,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  final TextEditingController reviewController = TextEditingController();
  double priceRating = 3;
  double serviceRating = 3;

  @override
  Widget build(BuildContext context) {
    double overall = (priceRating + serviceRating) / 2;

    return AlertDialog(
      title: const Text("Rate Technician"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: reviewController,
              decoration: const InputDecoration(
                hintText: "Write your review",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            _buildStarRating("Price Rating", priceRating, (v) {
              setState(() => priceRating = v);
            }),
            _buildStarRating("Service Rating", serviceRating, (v) {
              setState(() => serviceRating = v);
            }),
            const SizedBox(height: 10),
            Text(
              "Overall Rating: ${overall.toStringAsFixed(1)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _submitReview,
          child: const Text("Submit"),
        ),
      ],
    );
  }

  Widget _buildStarRating(
      String title, double rating, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (i) {
            final star = i + 1;
            return IconButton(
              onPressed: () => onChanged(star.toDouble()),
              icon: Icon(
                Icons.star,
                color: star <= rating ? Colors.amber : Colors.grey,
              ),
            );
          }),
        ),
      ],
    );
  }

  Future<void> _submitReview() async {
    widget.onSubmitStart(); // Show loading

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final reviewRef =
      FirebaseFirestore.instance.collection('reviews').doc(widget.requestId);

      // Check if review already exists
      final existing = await reviewRef.get();
      if (existing.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You already reviewed this job")),
          );
        }
        return;
      }

      double overall = (priceRating + serviceRating) / 2;

      // ✅ 1. Add review
      await reviewRef.set({
        "id": widget.requestId,
        "userId": user.uid,
        "technicianId": widget.technician.uid,
        "requestId": widget.requestId,
        "review": reviewController.text.trim(),
        "rating": overall,
        "priceRating": priceRating,
        "serviceRating": serviceRating,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // ✅ 2. Update request status
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({"status": "completed"});

      // ✅ 3. UPDATE TECHNICIAN STATS (THIS IS WHAT YOU ADDED)
      final technicianRef = FirebaseFirestore.instance
          .collection('technicians')
          .doc(widget.technician.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snap = await transaction.get(technicianRef);

        if (!snap.exists) return;

        final data = snap.data() as Map<String, dynamic>;

        double currentAvg = (data['avgRating'] ?? 0).toDouble();
        int totalReviews = (data['totalReviews'] ?? 0);
        int completedJobs = (data['completedJobs'] ?? 0);

        double newAvg =
            ((currentAvg * totalReviews) + overall) / (totalReviews + 1);

        transaction.update(technicianRef, {
          "avgRating": newAvg,
          "totalReviews": totalReviews + 1,
          "completedJobs": completedJobs + 1,
        });
      });

      // ✅ 4. Success message + close dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Review submitted successfully"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (error, stackTrace) {
      print("ERROR: $error");
      print("STACK TRACE: $stackTrace");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $error")),
        );
      }
    } finally {
      widget.onSubmitEnd(); // Stop loading
    }
  }
}