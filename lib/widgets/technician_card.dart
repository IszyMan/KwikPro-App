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

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && lastStatus != data.status) {
                _handleSideEffects(data.status);
              }
            });
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


  void _handleSideEffects(String status) {
    if (status == "accepted" && lastStatus != "accepted") {
      audioPlayer.play(AssetSource('notification.mp3'));
    }

    if (status == "pending" &&
        lastStatus != "pending" &&
        !isCounting) {
      startTimer();
    }

    if (status == "accepted" || status == "rejected") {
      isCounting = false;
    }

    lastStatus = status;
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

                  _buildStatusChip(data.status),
                  const SizedBox(height: 8),

                  _buildTopActionRow(context, data),
                  const SizedBox(height: 10),

                  if (data.requestId == null)
                    _buildBottomActionRow(context),
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
      "scheduled": ("📅 Appointment Pending", Colors.blue),
      "appointmentAccepted": ("✅ Appointment Confirmed", Colors.green),
      "appointmentRejected": ("❌ Appointment Declined", Colors.red),
      "cancelled": ("❌ Cancelled", Colors.grey),
      "expired": ("⌛ No Response", Colors.grey),
    };

    final item = map[status];
    if (item == null) return const SizedBox();

    return Chip(
      key: ValueKey(status),
      label: Text(item.$1),
      backgroundColor: item.$2,
    );
  }


  Widget _buildTopActionRow(
      BuildContext context,
      _RequestData data,
      ) {

    final id = data.requestId;
    final status = data.status;

    // NO REQUEST
    if (id == null) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _sendRequest(context),
              child: const Text("Request Now"),
            ),
          ),
        ],
      );
    }

    // PENDING
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
        ],
      );
    }

    // ACTIVE STATUSES
    final activeStatuses = [
      "accepted",
      "appointmentAccepted",
      "onTheWay",
      "arrived",
      "inProgress",
      "completionRequested",
    ];

    // CLOSED STATUSES
    final closedStatuses = [
      "completed",
      "rejected",
      "cancelled",
      "expired",
    ];

    // ACTIVE JOB UI
    if (activeStatuses.contains(status)) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _openActiveJob(id),
              child: const Text("View Job"),
            ),
          ),
        ],
      );
    }

    // CLOSED JOB UI
    if (closedStatuses.contains(status)) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _sendRequest(context),
              child: const Text("Request Again"),
            ),
          ),
        ],
      );
    }

    // FALLBACK UI
    return const SizedBox();
  }

  Widget _buildBottomActionRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _bookAppointment,
            child: const Text("Book Appointment"),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: _profileButton()),
      ],
    );
  }

  Widget _profileButton() {
    return OutlinedButton(
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
    );
  }


  Future<void> _sendRequest(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    final requestSessionId =
        "${user?.uid}_${widget.technician.uid}";

    if (user == null) return;

    startTimer();

    final existingAppointment =
    await FirebaseFirestore.instance
        .collection('requests')
        .where('userId', isEqualTo: user.uid)
        .where('technicianId', isEqualTo: widget.technician.uid)
        .where('type', isEqualTo: 'appointment')
        .where('isActive', isEqualTo: true)
        .get();

    if (existingAppointment.docs.isNotEmpty) {
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
      "type": "instant",
      "technicianName": widget.technician.name,
      "technicianImage": widget.technician.profilePic,
      "service": widget.technician.service,
      "serviceLocationAddress": widget.serviceLocationAddress,
      "description": widget.issueDescription,
      "imageUrl": widget.imageUrl.isNotEmpty ? widget.imageUrl : null,
      "userLat": widget.userLat,
      "userLng": widget.userLng,
      "sessionId": requestSessionId,
      "isActive": true,
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),
    });

    if (mounted) {
      setState(() {});
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Request sent")),
    );

    Future.delayed(const Duration(seconds: 30), () async {

      if (!mounted) return;

      final doc = await docRef.get();

      if (!doc.exists) return;

      final data = doc.data();

      if (data == null) return;

      if (data['isActive'] != true) return;

      final currentStatus = data['status'];

      if (currentStatus == "pending") {

        await docRef.update({
          "status": "expired",
          "isActive": false,
        });

      }

    });
  }

  Future<void> _bookAppointment() async {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 30),
      ),
      initialDate: DateTime.now(),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final appointmentDate = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    final existingAppointment =
    await FirebaseFirestore.instance
        .collection('requests')
        .where('userId', isEqualTo: user.uid)
        .where('technicianId',
        isEqualTo: widget.technician.uid)
        .where('type', isEqualTo: 'appointment')
        .where('status',
        whereIn: [
          "scheduled",
          "appointmentAccepted"
        ])
        .get();

    if (existingAppointment.docs.isNotEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You already booked an appointment",
          ),
        ),
      );

      return;
    }

    await FirebaseFirestore.instance.collection('requests').add({
      "userId": user.uid,
      "technicianId": widget.technician.uid,

      "type": "appointment",
      "jobType": "appointment",

      "technicianName": widget.technician.name,
      "technicianImage": widget.technician.profilePic,

      "service": widget.technician.service,
      "serviceLocationAddress": widget.serviceLocationAddress,
      "description": widget.issueDescription,

      "jobLocation": {
        "address": widget.serviceLocationAddress,
        "lat": widget.userLat,
        "lng": widget.userLng,
      },

      "imageUrl": widget.imageUrl.isNotEmpty
          ? widget.imageUrl
          : null,

      "status": "scheduled",
      "isActive": true,

      "appointmentDate":
      Timestamp.fromDate(appointmentDate),

      "appointmentTime":
      "${pickedTime.hour}:${pickedTime.minute}",

      "createdAt": FieldValue.serverTimestamp(),
    });

    if (mounted) setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Appointment booked for "
              "${DateFormat.yMMMd().add_jm().format(appointmentDate)}",
        ),
      ),
    );
  }

  Future<void> _cancelRequest(String requestId) async {

    await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .update({
      "status": "cancelled",
      "isActive": false,
    });

    if (mounted) {
      setState(() {
        isCounting = false;
      });
    }
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





