import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kwikpro/screens/user/view_technician_profile_screen.dart';
import '../../models/job_history_item.dart';
import '../../services/google_maps_service.dart';
import '../../services/location_repository.dart';
import '../../widgets/user_jobs/active_job_card.dart';
import 'package:kwikpro/models/technician_model.dart';
import '../../widgets/user_jobs/completed_job_card.dart';

class UserJobHistoryScreen extends StatefulWidget {
  const UserJobHistoryScreen({super.key});



  @override
  State<UserJobHistoryScreen> createState() =>
      _UserJobHistoryScreenState();
}

class _UserJobHistoryScreenState extends State<UserJobHistoryScreen> {

  final user = FirebaseAuth.instance.currentUser;
  final LocationRepository _locationRepository = const LocationRepository();

  /// Cache technicians
  final Map<String, TechnicianModel> _technicianCache = {};

  final activeStatuses = const [
    "pending",
    "accepted",
    "appointmentAccepted",
    "onTheWay",
    "arrived",
    "inProgress",
    "completionRequested",
  ];

  Stream<QuerySnapshot> getJobStream() {
    return FirebaseFirestore.instance
        .collection('requests')
        .where('userId', isEqualTo: user!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<TechnicianModel?> _getTechnician(String id) async {

    /// Already cached?
    if (_technicianCache.containsKey(id)) {
      return _technicianCache[id];
    }

    final doc = await FirebaseFirestore.instance
        .collection("technicians")
        .doc(id)
        .get();

    if (!doc.exists) return null;

    final technician = TechnicianModel.fromMap(doc.data()!);

    _technicianCache[id] = technician;

    return technician;
  }

  /// Preload ALL technicians in parallel
  Future<List<JobHistoryItem>> _buildJobItems(
      List<QueryDocumentSnapshot> jobs,
      ) async {

    final futures = jobs.map((job) async {
      final request = job.data() as Map<String, dynamic>;
      final techId = request["technicianId"];

      if (techId == null) return null;

      final technician = await _getTechnician(techId);

      if (technician == null) return null;

      double? distanceKm;
      int? etaMinutes;

      final techLat = technician.lat;
      final techLng = technician.lng;

      final userLat = (request["userLat"] as num?)?.toDouble();
      final userLng = (request["userLng"] as num?)?.toDouble();

      if (techLat != null &&
          techLng != null &&
          userLat != null &&
          userLng != null) {

        final route = await GoogleMapsService.getDistanceAndEta(
          originLat: techLat,
          originLng: techLng,
          destinationLat: userLat,
          destinationLng: userLng,
        );

        if (route != null) {
          distanceKm = (route["distanceKm"] as num?)?.toDouble();
          etaMinutes = (route["durationMinutes"] as num?)?.toInt();
        }
      }

      return JobHistoryItem(
        technician: technician,
        request: request,
        distanceKm: distanceKm,
        etaMinutes: etaMinutes,
      );
    });

    final results = await Future.wait(futures);

    return results.whereType<JobHistoryItem>().toList();
  }

  Future<void> _refresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("No user found"),
        ),
      );
    }

    return Scaffold(

        appBar: AppBar(
          title: const Text("My Jobs"),
        ),

        body: RefreshIndicator(
            onRefresh: _refresh,
            child: StreamBuilder<QuerySnapshot>(
                stream: getJobStream(),
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final jobs = snapshot.data!.docs;

                  return FutureBuilder<List<JobHistoryItem>>(
                    future: _buildJobItems(jobs),
                    builder: (context, itemSnap) {

                      if (!itemSnap.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final items = itemSnap.data!;

                      /// Active Job
                      JobHistoryItem? activeItem;

                      try {
                        activeItem = items.firstWhere(
                              (e) => activeStatuses.contains(
                            e.request["status"],
                          ),
                        );

                      } catch (_) {
                        activeItem = null;
                      }

                      /// Completed Jobs
                      final completedItems = items.where((e) {

                        return e.request["status"] == "completed";

                      }).toList();

                      return ListView(

                        padding: const EdgeInsets.fromLTRB(0,12,0,24,),
                        children: [

                          if (activeItem != null) ...[
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
                              child: Text(
                                "Current Job",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            ActiveJobCard(
                              item: activeItem,
                              onMessage: () {
                                // TODO Open chat
                              },
                              onCall: () {
                                // TODO Launch dialer
                              },
                            ),

                            const SizedBox(height: 20),
                          ],

                          /// ================= COMPLETED HEADER =================

                          Padding(
                            padding: const EdgeInsets.fromLTRB(16,0,16,12,),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                const Text(
                                  "Completed Jobs",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  "${completedItems.length} job${completedItems.length == 1 ? "" : "s"} completed",
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (completedItems.isEmpty)

                            Padding(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 50,
                              ),

                              child: Column(
                                children: [

                                  Icon(
                                    Icons.assignment_outlined,
                                    size: 70,
                                    color: Colors.grey.shade400,
                                  ),

                                  const SizedBox(height: 20),

                                  const Text(
                                    "No completed jobs yet.",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  Text(
                                    "When you hire a technician,\nyour completed jobs will appear here.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle( color: Colors.grey.shade600,height: 1.5,
                                    ),
                                  ),

                                  const SizedBox(height: 28),

                                  SizedBox( width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {},

                                      icon: const Icon(
                                        Icons.search,
                                      ),

                                      label: const Text(
                                        "Find Technician",
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (completedItems.isNotEmpty)

                            ...completedItems.map((item) {

                              final technician = item.technician;
                              final data = item.request;

                              return CompletedJobCard(
                                item: item,
                                onReview: () {

                                  /// TODO

                                },
                                onBookAgain: () {
                                  Navigator.push(context, MaterialPageRoute( builder: (_) =>
                                          ViewTechnicianProfileScreen(
                                            technician: technician,
                                            userLat: data["userLat"],
                                            userLng:  data["userLng"],
                                            serviceLocationAddress:  data["serviceLocationAddress"] ?? "",
                                            issueDescription:  data["description"] ?? "",
                                            imageUrl:  data["imageUrl"] ?? "",
                                            selectedSkills: const [],

                                          ),
                                  ),
                                  );
                                },
                              );
                            }),
                        ],
                      );
                    },
                  );
                },
            ),
        ),
    );
  }
}