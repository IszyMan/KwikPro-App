import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/app_card.dart';

class CompletedJobsScreen extends StatefulWidget {
  const CompletedJobsScreen({super.key});

  @override
  State<CompletedJobsScreen> createState() => _CompletedJobsScreenState();
}

class _CompletedJobsScreenState extends State<CompletedJobsScreen> {
  final String technicianId = FirebaseAuth.instance.currentUser!.uid;

  late Future<void> _loadFuture;

  int totalCompleted = 0;
  double avgPrice = 0;
  double avgService = 0;
  double avgOverall = 0;

  List<Map<String, dynamic>> reviewsWithJobs = [];

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadData();
  }

  /// LOAD DATA (CACHED)
  Future<void> _loadData() async {
    try {
      // REVIEWS FOR STATS
      final allReviewsSnap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('technicianId', isEqualTo: technicianId)
          .get();

      final allReviews = allReviewsSnap.docs;

      totalCompleted = allReviews.length;

      double totalPrice = 0;
      double totalService = 0;
      double totalOverall = 0;

      for (var doc in allReviews) {
        final data = doc.data();

        totalPrice += (data['priceRating'] as num?)?.toDouble() ?? 0;
        totalService += (data['serviceRating'] as num?)?.toDouble() ?? 0;
        totalOverall += (data['rating'] as num?)?.toDouble() ?? 0;
      }

      avgPrice = totalCompleted > 0 ? totalPrice / totalCompleted : 0;
      avgService = totalCompleted > 0 ? totalService / totalCompleted : 0;
      avgOverall = totalCompleted > 0 ? totalOverall / totalCompleted : 0;

      // LAST 10 REVIEWS
      final last10Snap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('technicianId', isEqualTo: technicianId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final lastReviews = last10Snap.docs;

      // REQUEST DATA MAP
      final requestIds =
      lastReviews.map((r) => r['requestId'] as String).toList();

      Map<String, Map<String, dynamic>> requestMap = {};

      if (requestIds.isNotEmpty) {
        final requestsSnap = await FirebaseFirestore.instance
            .collection('requests')
            .where(FieldPath.documentId, whereIn: requestIds)
            .get();

        for (var doc in requestsSnap.docs) {
          requestMap[doc.id] = doc.data();
        }
      }

      // MERGE DATA
      reviewsWithJobs = lastReviews.map((r) {
        final reviewData = r.data();
        final jobData = requestMap[r['requestId']] ?? {};

        return {
          "review": reviewData,
          "job": jobData,
        };
      }).toList();
    } catch (e) {
      debugPrint("LOAD ERROR: $e");
    }
  }

  void _refresh() {
    setState(() {
      _loadFuture = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Completed Jobs"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          )
        ],
      ),
      body: FutureBuilder(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Failed to load data"));
          }

          return _buildUI();
        },
      ),
    );
  }

  Widget _buildUI() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total Completed Jobs: $totalCompleted",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text("Your customers ratings"),
              Text("Avg Price: ${avgPrice.toStringAsFixed(1)}"),
              Text("Avg Service: ${avgService.toStringAsFixed(1)}"),
              Text("Avg Overall: ${avgOverall.toStringAsFixed(1)}"),
            ],
          ),
        ),

        const SizedBox(height: 12),

        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "Last 10 Reviews",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),

        ...reviewsWithJobs.map((item) {
          final review = item['review'];
          final job = item['job'];

          final overall = (review['rating'] ?? 0).toDouble();
          final price = (review['priceRating'] ?? 0).toDouble();
          final service = (review['serviceRating'] ?? 0).toDouble();

          final timestamp = review['createdAt'];
          final date =
          timestamp is Timestamp ? timestamp.toDate() : null;

          return AppCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(job['description'] ?? "No description"),
                const SizedBox(height: 4),
                Text(
                  job['serviceLocationAddress'] ?? "No address",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Text("Overall: ${overall.toStringAsFixed(1)}"),
                Text(
                  "Price: ${price.toStringAsFixed(1)}, Service: ${service.toStringAsFixed(1)}",
                ),
                const SizedBox(height: 6),
                Text(review['review'] ?? ""),
                if (date != null)
                  Text(
                    "${date.day}/${date.month}/${date.year}",
                    style: const TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}