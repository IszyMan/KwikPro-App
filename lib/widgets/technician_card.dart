import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kwikpro/core/status_badge.dart';
import 'package:kwikpro/models/technician_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kwikpro/screens/user/active_job_screen.dart';
import 'package:audioplayers/audioplayers.dart';

import '../screens/user/view_technician_profile_screen.dart';

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

  Map<String, dynamic>? techData;
  bool isTechLoading = true;

  Future<void> _loadTechnician() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('technicians')
          .doc(widget.technician.uid)
          .get();

      int completedJobs = 0;

      final reviewSnap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('technicianId', isEqualTo: widget.technician.uid)
          .get();

      completedJobs = reviewSnap.docs.length;

      if (doc.exists) {
        setState(() {
          techData = doc.data();
          techData!['completedJobs'] = completedJobs;
        });
      }
    } catch (e) {
      print("TECH LOAD ERROR: $e");
    }

    if (mounted) {
      setState(() => isTechLoading = false);
    }
  }


  void startTimer() {
    if (isCounting) return;

    countdown = 30;
    isCounting = true;

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return false;

      if (countdown <= 0) {
        setState(() {
          isCounting = false;
        });
        return false;
      }

      setState(() => countdown--);
      return isCounting;
    });
  }

  void _openActiveJob(String requestId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveJobScreen(
          technician: widget.technician,
          requestId: requestId,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadTechnician();
  }


  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('userId', isEqualTo: user.uid)
          .where('technicianId', isEqualTo: widget.technician.uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        final data = _extractRequestData(snapshot);
        _handleSideEffects(data.status);

        return _buildCard(context, data);
      },
    );
  }


  _RequestData _extractRequestData(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
      final doc = snapshot.data!.docs.first;
      final map = doc.data() as Map<String, dynamic>;

      return _RequestData(
        status: map['status'] ?? "none",
        requestId: doc.id,
      );
    }

    return _RequestData(status: "none", requestId: null);
  }


  void _handleSideEffects(String status) {
    if (status == "accepted" && lastStatus != "accepted") {
      audioPlayer.play(AssetSource('notification.mp3'));
    }

    if (status == "pending" && lastStatus != "pending") {
      startTimer();
    }

    if (status == "accepted" || status == "rejected") {
      isCounting = false;
    }

    lastStatus = status;
  }


  Widget _buildCard(BuildContext context, _RequestData data) {
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
                  _buildTechnicianInfo(distanceData),
                  const SizedBox(height: 6),

                  _buildStatusChip(data.status),
                  const SizedBox(height: 8),
                  _buildActionRow(context, data),
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


  Widget _buildTechnicianInfo(_DistanceData d) {
    final completedJobs = techData?['completedJobs'] ?? 0;
    final avgPrice = (techData?['avgPriceRating'] ?? 0).toDouble();
    final avgService = (techData?['avgServiceRating'] ?? 0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                widget.technician.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(width: 5),
           _buildVerifiedBadge(),

          ],
        ),

        Text(
          "Completed jobs: $completedJobs",
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.green,
          ),
        ),

        const SizedBox(height: 4),

        Row(
          children: [
            const Icon(Icons.star, size: 16, color: Colors.amber),
            Text("Price: ${avgPrice.toStringAsFixed(1)}"),
            const SizedBox(width: 3),
            Text("Service: ${avgService.toStringAsFixed(1)}"),
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


  Widget _buildStatusChip(String status) {
    final pendingText =
        "⏳ Waiting For Technician • ${countdown}s";
    final map = {
      "pending": (pendingText, Colors.blue),
      "accepted": ("✅ Accepted", Colors.green),
      "onTheWay": ("🚗 On The Way", Colors.orange),
      "arrived": ("📍 Arrived", Colors.teal),
      "inProgress": ("🛠️ In Progress", Colors.purple),
      "completionRequested": ("⏳ Awaiting Confirmation", Colors.amber),
      "completed": ("✅ Completed", Colors.green),
      "rejected": ("❌ Declined", Colors.red),
    };

    final item = map[status];
    if (item == null) return const SizedBox();

    return Chip(
      key: ValueKey(status),
      label: Text(item.$1),
      backgroundColor: item.$2,
    );
  }


  Widget _buildActionRow(BuildContext context, _RequestData data) {
    final id = data.requestId;
    final status = data.status;

    // ===== NO REQUEST =====
    if (id == null) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _sendRequest(context),
              child: const Text("Request"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
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
              child: const Text("Profile"),
            ),
          ),
        ],
      );
    }

    // ===== PENDING =====
    if (status == "pending") {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => _cancelRequest(id),
              child: const Text("Cancel"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
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
              child: const Text("Profile"),
            ),
          ),
        ],
      );
    }

    // ===== ACTIVE JOB =====
    if (status == "accepted" ||
        status == "onTheWay" ||
        status == "arrived" ||
        status == "inProgress" ||
        status == "completionRequested") {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _openActiveJob(id!),
              child: const Text("View Job"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
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
              child: const Text("Profile"),
            ),
          ),
        ],
      );
    }

    // ===== COMPLETED / REJECTED =====
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _sendRequest(context),
            child: const Text("Book Again"),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
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
            child: const Text("Profile"),
          ),
        ),
      ],
    );
  }


  Future<void> _sendRequest(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    startTimer();

    final existing = await FirebaseFirestore.instance
        .collection('requests')
        .where('userId', isEqualTo: user.uid)
        .where('technicianId', isEqualTo: widget.technician.uid)
        .where('status', whereIn: [
      "pending",
      "accepted",
      "onTheWay",
      "arrived",
      "inProgress",
      "completionRequested",
    ])
        .get();

    if (existing.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You already have an active request"),
        ),
      );
      return;
    }

    final docRef =
    await FirebaseFirestore.instance.collection('requests').add({
      "userId": user.uid,
      "technicianId": widget.technician.uid,
      "service": widget.technician.service,
      "serviceLocationAddress": widget.serviceLocationAddress,
      "description": widget.issueDescription,
      "imageUrl": widget.imageUrl.isNotEmpty ? widget.imageUrl : null,
      "userLat": widget.userLat,
      "userLng": widget.userLng,
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Request sent")),
    );

    Future.delayed(const Duration(seconds: 30), () async {
      final doc = await docRef.get();

      if (!doc.exists) return;

      final currentStatus = doc.data()?['status'];

      if (currentStatus == "pending") {
        await docRef.update({
          "status": "rejected",
        });
      }
    });
  }

  Future<void> _cancelRequest(String requestId) async {
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .update({"status": "rejected"});

    setState(() => isCounting = false);
  }
}

/// ---------------- HELPER CLASSES ----------------
class _RequestData {
  final String status;
  final String? requestId;

  _RequestData({required this.status, required this.requestId});
}

class _DistanceData {
  final double distance;
  final String eta;

  _DistanceData({required this.distance, required this.eta});
}



