import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kwikpro/core/status_badge.dart';
import 'package:kwikpro/models/technician_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kwikpro/screens/user/active_job_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import '../screens/user/view_technician_profile_screen.dart';
import '../services/notification_service.dart';

class TechnicianCard extends StatefulWidget {
  final TechnicianModel technician;
  final double? userLat;
  final double? userLng;
  final String serviceLocationAddress;
  final String issueDescription;
  final String imageUrl;
  final List<String> selectedSkills;


  const TechnicianCard({
    super.key,
    required this.technician,
    required this.serviceLocationAddress,
    this.userLat,
    this.userLng,
    required this.selectedSkills,
    required this.issueDescription,
    required this.imageUrl,
  });

  @override
  State<TechnicianCard> createState() => _TechnicianCardState();
}

class _TechnicianCardState extends State<TechnicianCard> {
  int countdown = 30;
  bool isCounting = false;
  String lastStatus = "";
  final AudioPlayer audioPlayer = AudioPlayer();
  Stream<QuerySnapshot>? _requestStream;


  Map<String, dynamic>? techData;
  bool isTechLoading = true;



  Future<void> _loadTechnician() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('technicians')
          .doc(widget.technician.uid)
          .get();

      if (doc.exists) {
        techData = doc.data() as Map<String, dynamic>;
      } else {
        techData = {};
      }

    } catch (e) {
      debugPrint("TECH LOAD ERROR: $e");
    }

    if (mounted) {
      setState(() => isTechLoading = false);
    }
  }





  @override
  void initState() {
    super.initState();

    _loadTechnician();

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      _requestStream = FirebaseFirestore.instance
          .collection('requests')
          .where('userId', isEqualTo: user.uid)
          .where('technicianId', isEqualTo: widget.technician.uid)
          .where(
        'status',
        whereIn: [
          'pending',
          'accepted',
          'onTheWay',
          'arrived',
          'inProgress',
          'completionRequested',
          'scheduled',
          'appointmentAccepted',
        ],
      )
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots();
    }
  }


  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  Future<bool> _hasWorkedBefore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final snap = await FirebaseFirestore.instance
        .collection('requests')
        .where('userId', isEqualTo: user.uid)
        .where('technicianId', isEqualTo: widget.technician.uid)
        .where('status', isEqualTo: 'completed')
        .limit(1)
        .get();

    return snap.docs.isNotEmpty;
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();


    return FutureBuilder<bool>(
      future: _hasWorkedBefore(),
      builder: (context, historySnap) {
        final hasWorkedBefore = historySnap.data ?? false;

        return StreamBuilder<QuerySnapshot>(
          stream: _requestStream,
          builder: (context, snapshot) {
            final data = _extractRequestData(snapshot);


            return _buildCard(
              context,
              data,
              hasWorkedBefore: hasWorkedBefore,
            );
          },
        );
      },
    );
  }


  _RequestData _extractRequestData(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return _RequestData(
        status: "none",
        requestId: null,
        type: "",
      );
    }

    final doc = snapshot.data!.docs.first;
    final map = doc.data() as Map<String, dynamic>;

    return _RequestData(
      status: map['status'] ?? "none",
      requestId: doc.id,
      type: map['type'] ?? "",
    );
  }




  Widget _buildCard(BuildContext context, _RequestData data, {required bool hasWorkedBefore}) {
    final distanceData = _calculateDistance();

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTechnicianInfo(distanceData, hasWorkedBefore: hasWorkedBefore,),
                  const SizedBox(height: 6),

                ],
              ),
            ),


          ],
        ),
      ),
    );
  }


  _DistanceData _calculateDistance() {
    if (widget.userLat == null ||
        widget.userLng == null ||
        widget.technician.lat == null ||
        widget.technician.long == null) {
      return _DistanceData(distance: 0, eta: "--");
    }

    final distanceKm = Geolocator.distanceBetween(
      widget.userLat!,
      widget.userLng!,
      widget.technician.lat!,
      widget.technician.long!,
    ) /
        1000;

    final minutes = ((distanceKm / 40) * 60).ceil();

    return _DistanceData(
      distance: distanceKm,
      eta: "$minutes min away",
    );
  }


  Widget _buildAvatar() {
    final image = widget.technician.profilePic;

    final isOnline = widget.technician.isOnline;

    return Stack(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundImage:
          (image != null && image.isNotEmpty)
              ? NetworkImage(image)
              : null,
          child: (image == null || image.isEmpty)
              ? const Icon(Icons.person)
              : null,
        ),

        //Status Dot
        Positioned(
          right: 0,
          bottom: 35,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? Colors.green : Colors.yellow,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildTechnicianInfo(_DistanceData d, {
    required bool hasWorkedBefore,
  }) {

    final completedJobs =
        techData?['completedJobs'] ?? 0;

    final avgRating =
        (techData?['avgRating'] as num?)
            ?.toDouble() ??
            0.0;


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                widget.technician.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),

            const SizedBox(width: 5),

            _buildVerifiedBadge(),

            if (hasWorkedBefore) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Worked before",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ]
          ],
        ),

        Row(
          children: [

            // RATING NUMBER
            Text(
              avgRating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),

            const SizedBox(width: 6),

            // STARS
            ..._buildStars(avgRating),

            const SizedBox(width: 4),



            // JOB COUNT
            Text(
              "($completedJobs jobs)",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Row(
          children: [
            const Icon(Icons.location_on, size: 16),
            Text('${d.distance.toStringAsFixed(1)} km'),
            const SizedBox(width: 10),
            const Icon(Icons.timer, size: 16),
            Text(d.eta),
          ],
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ViewTechnicianProfileScreen(
                    technician: widget.technician,
                    userLat: widget.userLat,
                    userLng: widget.userLng,
                    serviceLocationAddress: widget.serviceLocationAddress,
                    issueDescription: widget.issueDescription,
                    imageUrl: widget.imageUrl,
                    selectedSkills: widget.selectedSkills,
                  ),
                ),
              );
            },
            child: const Text("View Profile"),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifiedBadge() {
    return StatusBadge(
      label:
      widget.technician.isVerified ? "Verified" : "Not Verified",
      color: widget.technician.isVerified
          ? Colors.green
          : Colors.orangeAccent,
      icon: widget.technician.isVerified
          ? Icons.check_circle
          : Icons.block,
    );
  }


  List<Widget> _buildStars(double rating) {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;

    return [
      for (int i = 0; i < fullStars; i++)
        const Icon(Icons.star, size: 16, color: Colors.amber),

      if (hasHalfStar)
        const Icon(Icons.star_half, size: 16, color: Colors.amber),
    ];
  }



}

/// ---------------- HELPER CLASSES ----------------
class _RequestData {
  final String status;
  final String? requestId;
  final String type;

  _RequestData({
    required this.status,
    required this.requestId,
    required this.type,
  });
}

class _DistanceData {
  final double distance;
  final String eta;

  _DistanceData({required this.distance, required this.eta});
}





