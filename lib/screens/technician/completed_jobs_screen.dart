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

  List<Map<String, dynamic>> completedJobsWithReviews = [];

  int totalCompleted = 0;
  double avgPrice = 0;
  double avgService = 0;
  double avgOverall = 0;

  Map<String, dynamic>? technicianData;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadData();
  }

  // ================= LOAD DATA =================
  Future<void> _loadData() async {
    try {
      completedJobsWithReviews.clear();

      // ================= TECHNICIAN DATA (SOURCE OF TRUTH) =================
      final techDoc = await FirebaseFirestore.instance
          .collection('technicians')
          .doc(technicianId)
          .get();

      technicianData = techDoc.data();

      totalCompleted = technicianData?['completedJobs'] ?? 0;

      // ================= REVIEWS =================
      final reviewsSnap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('technicianId', isEqualTo: technicianId)
          .get();

      Map<String, Map<String, dynamic>> reviewMap = {};

      double totalPrice = 0;
      double totalService = 0;
      double totalOverall = 0;

      for (var doc in reviewsSnap.docs) {
        final data = doc.data();

        final requestId = data['requestId'];

        if (requestId != null) {
          reviewMap[requestId] = data;
        }

        totalPrice += (data['priceRating'] ?? 0).toDouble();
        totalService += (data['serviceRating'] ?? 0).toDouble();
        totalOverall += (data['rating'] ?? 0).toDouble();
      }

      final reviewCount = reviewsSnap.docs.length;

      avgPrice = reviewCount > 0 ? totalPrice / reviewCount : 0;
      avgService = reviewCount > 0 ? totalService / reviewCount : 0;
      avgOverall = reviewCount > 0 ? totalOverall / reviewCount : 0;

      // ================= COMPLETED JOBS LIST (OPTIONAL BUT SAFE) =================
      // Still needed for UI list
      final completedSnap = await FirebaseFirestore.instance
          .collection('requests')
          .where('technicianId', isEqualTo: technicianId)
          .where('status', isEqualTo: 'completed')
          .get();

      completedJobsWithReviews = completedSnap.docs.map((jobDoc) {
        final job = jobDoc.data();
        final jobId = jobDoc.id;

        return {
          "job": job,
          "review": reviewMap[jobId] ?? {},
        };
      }).toList();

      completedJobsWithReviews.sort((a, b) {
        final aTime = a['job']['timeline']?['completedAt'];
        final bTime = b['job']['timeline']?['completedAt'];

        if (aTime == null || bTime == null) return 0;

        return (bTime as Timestamp).compareTo(aTime as Timestamp);
      });

      if (mounted) setState(() {});
    } catch (e, stack) {
      debugPrint("LOAD ERROR: $e");
      debugPrintStack(stackTrace: stack);
    }
  }

  // ================= REFRESH =================
  void _refresh() {
    setState(() {
      _loadFuture = _loadData();
    });
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Completed Jobs"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return _buildUI();
        },
      ),
    );
  }

  // ================= SINGLE SCROLL UI =================
  Widget _buildUI() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ================= SUMMARY =================
        Text(
          "Total Completed Jobs: $totalCompleted",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),

        const SizedBox(height: 6),
        const Text("Your customers ratings"),

        Text("Avg Price: ${avgPrice.toStringAsFixed(1)}"),
        Text("Avg Service: ${avgService.toStringAsFixed(1)}"),
        Text("Avg Overall: ${avgOverall.toStringAsFixed(1)}"),

        const SizedBox(height: 20),

        const Text(
          "Completed Jobs",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        if (completedJobsWithReviews.isEmpty)
          const Center(child: Text("No completed jobs yet"))
        else
          ...completedJobsWithReviews.map(_buildJobCard),
      ],
    );
  }

  // ================= JOB CARD =================
  Widget _buildJobCard(Map<String, dynamic> item) {
    final job = item['job'] ?? {};
    final review = item['review'] ?? {};

    final completedAt =
    (job['timeline']?['completedAt'] as Timestamp?)?.toDate();

    final location = job['serviceLocationAddress'] ??
        job['jobLocation']?['address'] ??
        "No location";

    final priceRating = ((review['priceRating'] ?? 0) as num).toDouble();
    final serviceRating = ((review['serviceRating'] ?? 0) as num).toDouble();
    final overall = ((review['rating'] ?? 0) as num).toDouble();
    final comment = review['review'] ?? "";

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${job['service'] ?? 'Service'} Services rendered",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(location, style: const TextStyle(color: Colors.grey)),

          if ((job['description'] ?? "").toString().isNotEmpty)
            Text("📝 ${job['description']}"),

          const SizedBox(height: 8),

          if (completedAt != null)
            Text(
              "📅 Completed: ${completedAt.day}/${completedAt.month}/${completedAt.year}",
              style: const TextStyle(color: Colors.grey),
            ),

          const Divider(),

          if (review.isNotEmpty) ...[
            Text("💬 $comment"),
            Text("💰 Price rating: $priceRating"),
            Text("🛠 Service rating: $serviceRating"),
            Text("⭐ Overall rating: $overall"),
          ] else
            const Text(
              "No review yet",
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }
}