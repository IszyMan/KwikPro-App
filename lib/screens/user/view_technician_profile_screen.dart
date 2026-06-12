import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/technician_model.dart';
import '../../services/notification_service.dart';
import 'active_job_screen.dart';

class ViewTechnicianProfileScreen extends StatefulWidget {
  final TechnicianModel technician;
  final double? userLat;
  final double? userLng;
  final String serviceLocationAddress;
  final String issueDescription;
  final String imageUrl;
  final List<String> selectedSkills;

  const ViewTechnicianProfileScreen({
    super.key,
    required this.technician,
    required this.userLat,
    required this.userLng,
    required this.serviceLocationAddress,
    required this.issueDescription,
    required this.imageUrl,
    required this.selectedSkills,
  });

  @override
  State<ViewTechnicianProfileScreen> createState() =>
      _ViewTechnicianProfileScreenState();
}

class _ViewTechnicianProfileScreenState
    extends State<ViewTechnicianProfileScreen>
    with SingleTickerProviderStateMixin {

  Stream<QuerySnapshot>? _requestStream;
  String _status = "none";
  String? _requestId;
  String? _requestType;

  late TabController _tabController;

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

    _tabController = TabController(length: 2, vsync: this);

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      _requestStream = FirebaseFirestore.instance
          .collection('requests')
          .where('userId', isEqualTo: user.uid)
          .where('technicianId', isEqualTo: widget.technician.uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// FETCH REVIEW STATS
  Future<Map<String, dynamic>> _getStats() async {

    final snap = await FirebaseFirestore.instance
        .collection('reviews')
        .where(
      'technicianId',
      isEqualTo: widget.technician.uid).get();

    final docs = snap.docs;

    final count = docs.length;


    final techDoc = await FirebaseFirestore.instance
        .collection('technicians')
        .doc(widget.technician.uid)
        .get();

    final techData = techDoc.data() ?? {};

    if (count == 0) {
      return {
        "completedJobs": 0,
        "avgRating": 0.0,
        "avgPrice": 0.0,
        "avgService": 0.0,
      };
    }

    double totalRating = 0;
    double totalPrice = 0;
    double totalService = 0;

    for (final doc in docs) {

      final data = doc.data();

      totalRating +=
          (data['rating'] ?? 0).toDouble();

      totalPrice +=
          (data['priceRating'] ?? 0).toDouble();

      totalService +=
          (data['serviceRating'] ?? 0).toDouble();
    }

    return {
      "completedJobs": techData['completedJobs'] ?? 0,
      "avgRating": totalRating / count,
      "avgPrice": totalPrice / count,
      "avgService": totalService / count,
    };
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(widget.technician.name),
      ),

      body: FutureBuilder<Map<String, dynamic>>(

        future: _getStats(),

        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text("Failed to load profile"),
            );
          }

          final data = snapshot.data!;

          final completedJobs =
          data['completedJobs'];

          final avgRating =
          data['avgRating'];


          return Column(
            children: [

              /// BODY
              Expanded(
                child: SingleChildScrollView(

                  padding: const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      /// HEADER
                      Row(
                        children: [

                          CircleAvatar(
                            radius: 42,

                            backgroundImage:
                            (widget.technician.profilePic
                                ?.isNotEmpty ??
                                false)
                                ? NetworkImage(
                                widget.technician.profilePic!)
                                : null,

                            child:
                            (widget.technician.profilePic
                                ?.isEmpty ??
                                true)
                                ? const Icon(
                              Icons.person,
                              size: 40,
                            )
                                : null,
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,

                              children: [

                                Text(
                                  widget.technician.name,

                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  widget.technician.service,

                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[700],
                                  ),
                                ),

                                const SizedBox(height: 10),

                                Row(
                                  children: [

                                    Icon(
                                      Icons.verified,
                                      color:
                                      widget.technician
                                          .isVerified
                                          ? Colors.green
                                          : Colors.grey,
                                      size: 18,
                                    ),

                                    const SizedBox(width: 5),

                                    Text(
                                      widget.technician
                                          .isVerified
                                          ? "Verified Technician"
                                          : "Not Verified",
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),

                      const SizedBox(height: 24),

                      /// STATS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [

                          /// Jobs Completed
                          _miniStat(
                            icon: Icons.work,
                            label: "Completed Jobs",
                            value: "$completedJobs",
                            color: Colors.green,
                          ),

                          /// Rating + Stars
                          Row(
                            children: [
                              _miniStat(
                                icon: Icons.star,
                                label: "Rating",
                                value: avgRating.toStringAsFixed(1),
                                color: Colors.blue,
                              ),

                              const SizedBox(width: 6),

                              Row(
                                children: _buildStars(avgRating),
                              ),
                            ],
                          ),
                        ],
                      ),



                      const SizedBox(height: 24),

                      /// REQUEST / STATUS SECTION
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _requestStream,
                          builder: (context, snapshot) {

                            // DEFAULT STATE
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              _status = "none";
                              _requestId = null;

                              return _buildActionPanel();
                            }

                            final doc = snapshot.data!.docs.first;
                            final data = doc.data() as Map<String, dynamic>;

                            // UPDATE STATE FROM FIRESTORE
                            _status = data['status'] ?? "none";
                            _requestId = doc.id;
                            _requestType = data['type'] ?? "instant";

                            // SIDE EFFECTS (optional but important)
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                // you can later add sound/notifications here safely
                              }
                            });

                            return _buildActionPanel();
                          },
                        ),
                      ),

                      /// TAB BAR
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius:
                          BorderRadius.circular(12),
                        ),

                        child: TabBar(

                          controller: _tabController,

                          indicator: UnderlineTabIndicator(
                            borderSide: BorderSide(
                              width: 5,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),

                          labelColor: Colors.blue,

                          unselectedLabelColor:
                          Colors.black87,

                          tabs: const [

                            Tab(text: "Technician Bio"),

                            Tab(text: "Previous Work images"),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        height: 550,

                        child: TabBarView(

                          controller: _tabController,

                          children: [

                            /// BIO TAB
                            _buildBio(),

                            /// WORK TAB
                            _buildGallery(
                              widget.technician
                                  .previousWorkImages ??
                                  [],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            ],
          );
        },
      ),
    );
  }

  /// BIO TAB
  Widget _buildBio() {

    return SingleChildScrollView(

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          /// AREA
          const Text(
            "Area of Operation",

            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            widget.technician.address,
          ),

          const SizedBox(height: 20),

          /// EXPERIENCE
          const Text(
            "Years of Experience",

            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "${widget.technician.yearsOfExperience} years",
          ),

          const SizedBox(height: 24),

          /// SKILLS
          const Text(
            "Skills",

            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,

            children:
            (widget.technician.skills ?? [])
                .map(
                  (skill) => Chip(
                label: Text(skill),
              ),
            )
                .toList(),
          ),
        ],
      ),
    );
  }

  /// IMAGE GALLERY
  Widget _buildGallery(List<String> images) {

    if (images.isEmpty) {
      return const Center(
        child: Text(
          "No images uploaded yet",
        ),
      );
    }

    return GridView.builder(

      itemCount: images.length,

      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(

        crossAxisCount: 2,

        crossAxisSpacing: 10,

        mainAxisSpacing: 10,
      ),

      itemBuilder: (context, index) {

        return GestureDetector(

          onTap: () {

            showDialog(

              context: context,

              builder: (_) {

                return Dialog(

                  backgroundColor: Colors.black,

                  insetPadding:
                  const EdgeInsets.all(10),

                  child: InteractiveViewer(
                    child: Image.network(
                      images[index],
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            );
          },

          child: ClipRRect(

            borderRadius:
            BorderRadius.circular(14),

            child: Image.network(
              images[index],
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  /// STATS CHIP
  Widget _miniStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          "$value $label",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _sendRequest(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    final requestSessionId =
        "${user?.uid}_${widget.technician.uid}";

    if (user == null) return;



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

    await NotificationService.send(
      recipientId: widget.technician.uid,
      title: "New Job Request",
      body: "A customer requested your service",
      requestId: docRef.id,
      type: "job_request",
    );

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

    final appointmentRef =
    await FirebaseFirestore.instance
        .collection('requests')
        .add({
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

    await NotificationService.send(
      recipientId: widget.technician.uid,
      title: "New Appointment",
      body:
      "Appointment booked for ${DateFormat.yMMMd().add_jm().format(appointmentDate)}",
      requestId: appointmentRef.id,
      type: "appointment",
    );



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

    await NotificationService.send(
      recipientId: widget.technician.uid,
      title: "Job Cancelled",
      body: "Customer cancelled the request",
      requestId: requestId,
      type: "job_cancelled",
    );


  }

  Widget _buildActionPanel() {
    if (_requestId == null) {
      return _buildInitialActions();
    }

    if (_status == "pending" || _status == "scheduled") {
      return _buildPendingActions();
    }

    if ([
      "accepted",
      "appointmentAccepted",
      "onTheWay",
      "arrived",
      "inProgress",
      "completionRequested"
    ].contains(_status)) {
      return _buildActiveJobActions();
    }

    return _buildInitialActions();
  }


  Widget _buildInitialActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: _actionChipButton(
            icon: Icons.flash_on,
            label: "Request Now",
            color: Colors.orange,
            onTap: () => _sendRequest(context),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: _actionChipButton(
            icon: Icons.calendar_month,
            label: "Book Appointment",
            color: Colors.blue,
            onTap: _bookAppointment,
          ),
        ),
      ],
    );
  }

  Widget _buildPendingActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statusChip(_status),

        const SizedBox(height: 10),

        Text(
          _requestType == "appointment"
              ? "Appointment awaiting technician confirmation..."
              : "Waiting for technician response...",
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: _actionChipButton(
            icon: Icons.cancel,
            label: "Cancel Request",
            color: Colors.red,
            onTap: () => _cancelRequest(_requestId!),
          ),
        ),
      ],
    );
  }


  Widget _buildActiveJobActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statusChip(_status),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: _actionChipButton(

            icon: Icons.work,
            label: "View Job Progress",
            color: Colors.green,
            onTap: () => _openActiveJob(_requestId!),
          ),
        ),
      ],
    );
  }


  Widget _statusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case "pending":
        color = Colors.orange;
        label = "Pending";
        break;

      case "accepted":
      case "appointmentAccepted":
        color = Colors.blue;
        label = "Accepted";
        break;

      case "onTheWay":
        color = Colors.purple;
        label = "On the way";
        break;

      case "arrived":
        color = Colors.indigo;
        label = "Arrived";
        break;

      case "inProgress":
        color = Colors.teal;
        label = "In Progress";
        break;

      case "completionRequested":
        color = Colors.amber;
        label = "Completion Requested";
        break;

      case "completed":
        color = Colors.green;
        label = "Completed";
        break;

      case "scheduled":
        color = Colors.orange;
        label = "Scheduled";
        break;

      case "expired":
        color = Colors.grey;
        label = "Expired";
        break;

      case "cancelled":
        color = Colors.red;
        label = "Cancelled";
        break;

      default:
        color = Colors.grey;
        label = "No Status";
    }

    return SizedBox(
        width: double.infinity,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_statusIcon(status), color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
    )
    );
  }


  IconData _statusIcon(String status) {
    switch (status) {
      case "pending":
        return Icons.hourglass_bottom;

      case "accepted":
      case "appointmentAccepted":
        return Icons.verified;

      case "onTheWay":
        return Icons.directions_car;

      case "arrived":
        return Icons.location_on;

      case "inProgress":
        return Icons.build;

      case "completionRequested":
        return Icons.task_alt;

      case "completed":
        return Icons.check_circle;

      case "scheduled":
        return Icons.event;

      case "cancelled":
        return Icons.cancel;

      default:
        return Icons.info;
    }
  }


  Widget _actionChipButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.blue,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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