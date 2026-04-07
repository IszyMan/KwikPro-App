import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kwikpro/core/status_badge.dart';
import 'package:kwikpro/models/technician_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kwikpro/screens/user/active_job_screen.dart';
import 'package:audioplayers/audioplayers.dart';

class TechnicianCard extends StatefulWidget {
  final TechnicianModel technician;
  final double? userLat;
  final double? userLng;
  final String serviceLocationAddress;
  final String issueDescription;
  final String imageUrl;

  const TechnicianCard({
    super.key,
    required this.technician,
    required this.serviceLocationAddress,
    this.userLat,
    this.userLng,
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

      if (doc.exists) {
        techData = doc.data();
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
        isCounting = false;
        return false;
      }

      setState(() => countdown--);
      return isCounting;
    });
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

    if (status == "pending") {
      startTimer();
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

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildStatusChip(data.status),
                  ),
                ],
              ),
            ),

            _buildButton(context, data),
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

    return CircleAvatar(
      radius: 25,
      backgroundImage:
      (image != null && image.isNotEmpty) ? NetworkImage(image) : null,
      child: (image == null || image.isEmpty)
          ? const Icon(Icons.person)
          : null,
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
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 5),
            _buildVerifiedBadge(),
            const SizedBox(height: 6),




          ],
        ),

        Text(widget.technician.service),
        Text(widget.technician.address,
            style: const TextStyle(color: Colors.grey)),

        Text(
          "jobs completed: $completedJobs",
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
    final map = {
      "pending": ("⏳ Waiting For Technician", Colors.blue.shade200),
      "accepted": ("✅ Accepted", Colors.green.shade200),
      "started": ("🛠️ In Progress", Colors.purple.shade200),
      "completed": ("✅ Completed", Colors.green.shade300),
      "rejected": ("❌ Declined", Colors.red.shade200),
      "cancelled": ("⚠️ No Reply", Colors.orange.shade200),
    };

    if (!map.containsKey(status)) return const SizedBox();

    final item = map[status]!;

    return Chip(
      key: ValueKey(status),
      label: Text(item.$1),
      backgroundColor: item.$2,
    );
  }


  Widget _buildButton(BuildContext context, _RequestData data) {
    switch (data.status) {
      case "pending":
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: null,
              child: Text("Waiting... $countdown s"),
            ),
            const SizedBox(height: 6),
            ElevatedButton.icon(
              icon: const Icon(Icons.close),
              label: const Text("Cancel"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: data.requestId == null
                  ? null
                  : () => _cancelRequest(data.requestId!),
            ),
          ],
        );

      case "accepted":
        return ElevatedButton(
          style:
          ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () {
            if (data.requestId == null) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ActiveJobScreen(
                  technician: widget.technician,
                  requestId: data.requestId!,
                ),
              ),
            );
          },
          child: const Text("View Technician"),
        );

      case "rejected":
      case "cancelled":
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
            data.status == "rejected" ? Colors.red : Colors.orange,
          ),
          onPressed: () => _sendRequest(context),
          child: Text(data.status == "rejected"
              ? "Retry"
              : "Try Again"),
        );

      case "started":
        return ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade200),
          onPressed: () {
            if (data.requestId == null) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ActiveJobScreen(
                  technician: widget.technician,
                  requestId: data.requestId!,
                ),
              ),
            );
          },
          child: const Text("View Job In Progress"),
        );

      default:
      // Check if last completed request has rating/review
        if (data.status == "completed") {
          return ElevatedButton(
            onPressed: () => _sendRequest(context),
            child: const Text("Book Again"),
          );
        } else {
          return ElevatedButton(
            onPressed: () => _sendRequest(context),
            child: const Text("Request"),
          );
        }
    }
  }


  Future<void> _sendRequest(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    startTimer();

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

      if (doc.exists && doc['status'] == 'pending') {
        await docRef.update({"status": "cancelled"});
      }
    });
  }

  Future<void> _cancelRequest(String requestId) async {
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .update({"status": "cancelled"});

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

