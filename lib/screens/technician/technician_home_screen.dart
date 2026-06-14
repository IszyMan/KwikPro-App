import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kwikpro/screens/technician/edit_technician_profile_screen.dart';
import 'package:kwikpro/screens/technician/technician_job_history_screen.dart';
import 'package:kwikpro/screens/technician/technician_notification_screen.dart';
import 'package:kwikpro/screens/technician/technician_profile_screen.dart';
import 'package:kwikpro/screens/user/privacy_policy.dart';
import '../../services/notification_service.dart';
import '../../widgets/showcase_feed_widget.dart';
import '../onboarding/welcome_screen.dart';
import 'package:intl/intl.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';

import '../user/terms_and_conditions.dart';

class TechnicianHomeScreen extends ConsumerStatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  ConsumerState<TechnicianHomeScreen> createState() =>
      _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends ConsumerState<TechnicianHomeScreen> {
  StreamSubscription<Position>? _positionStream;
  final user = FirebaseAuth.instance.currentUser;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Timer? timer;
  Map<String, Timer> requestTimers = {};
  Map<String, int> countdowns = {};

  Map<String, dynamic>? _technicianData;

  String? _verificationId;

  @override
  void initState() {
    super.initState();
    _fetchTechnicianData();
    NotificationService.saveFcmToken(collection: 'technicians');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.setupForegroundNotifications(context);
    });
  }



  Future<void> _fetchTechnicianData() async {
    if (user == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('technicians')
        .doc(user!.uid)
        .get();

    if (snapshot.exists) {
      setState(() {
        _technicianData = snapshot.data() as Map<String, dynamic>;
      });
    }
  }





  Future<void> _showDeleteAccountDialog() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "Deleting your account will permanently remove your profile, requests, reviews and account data.\n\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sendDeleteOTP();
            },
            child: const Text(
              "Continue",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendDeleteOTP() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.phoneNumber == null) return;

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: user.phoneNumber!,
      verificationCompleted: (PhoneAuthCredential credential) async {},

      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "OTP failed")),
        );
      },

      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _showOTPDialog();
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _showOTPDialog() async {
    final otpController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Verify OTP"),
        content: TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: "Enter OTP",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              await _deleteAccount(
                otpController.text.trim(),
              );
            },
            child: const Text(
              "Delete Account",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(String otpCode) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || _verificationId == null) return;

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otpCode,
      );

      // re-authenticate
      await user.reauthenticateWithCredential(credential);

      final uid = user.uid;

      // delete technician document
      await FirebaseFirestore.instance
          .collection('technicians')
          .doc(uid)
          .delete();

      // delete requests
      final requests = await FirebaseFirestore.instance
          .collection('requests')
          .where('technicianId', isEqualTo: uid)
          .get();

      for (final doc in requests.docs) {
        await doc.reference.delete();
      }

      // delete notifications
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .get();

      for (final doc in notifications.docs) {
        await doc.reference.delete();
      }

      // delete reviews
      final reviews = await FirebaseFirestore.instance
          .collection('reviews')
          .where('technicianId', isEqualTo: uid)
          .get();

      for (final doc in reviews.docs) {
        await doc.reference.delete();
      }

      // delete firebase auth account
      await user.delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account deleted successfully"),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => WelcomeScreen(),
        ),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Authentication failed"),
        ),
      );
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Something went wrong"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Delete failed: $e"),
        ),
      );
    }
  }



  @override
  void dispose() {
    _positionStream?.cancel();
    timer?.cancel();
    requestTimers.forEach((key, t) => t.cancel());
    super.dispose();
  }

  void _updateOnlineStatus(bool value) async {
    if (user == null) return;

    if (value) {
      _positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 10,
        ),
      ).listen((Position position) async {
        await FirebaseFirestore.instance
            .collection('technicians')
            .doc(user!.uid)
            .update({
          'isOnline': true,
          'lat': position.latitude,
          'long': position.longitude,
        });
      });
    } else {
      await _positionStream?.cancel();
      _positionStream = null;
      await FirebaseFirestore.instance
          .collection('technicians')
          .doc(user!.uid)
          .update({'isOnline': false});
    }
  }

  Future<void> _updateStatus(
      String requestId,
      String status,
      ) async {

    await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .update({
      "status": status,
    });

    final requestDoc =
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .get();

    final data = requestDoc.data();

    if (data == null) return;

    final userId = data['userId'];

    if (status == "accepted") {
      await NotificationService.send(
        recipientId: userId,
        title: "Job Accepted",
        body: "Technician accepted your request",
        requestId: requestId,
        type: "job_accepted",
      );
    }

    if (status == "rejected") {
      await NotificationService.send(
        recipientId: userId,
        title: "Job Rejected",
        body: "Technician declined your request",
        requestId: requestId,
        type: "job_rejected",
      );
    }

    requestTimers[requestId]?.cancel();
  }

  void startCountdown(String requestId) {
    countdowns[requestId] = 30;
    requestTimers[requestId]?.cancel();

    requestTimers[requestId] = Timer.periodic(Duration(seconds: 1), (_) {
      if (!mounted) {
        requestTimers[requestId]?.cancel();
        return;
      }
      setState(() {
        countdowns[requestId] = (countdowns[requestId]! - 1);

        if (countdowns[requestId]! <= 0) {
          requestTimers[requestId]?.cancel();
          _updateStatus(requestId, "declined");
        }
      });
    });
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'declined':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(body: Center(child: Text("No user found")));
    }

    final name = _technicianData?['name'] ?? 'Technician';
    final profileUrl = _technicianData?['profilePic'] ?? '';

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            SizedBox(width: 4),

            if (_technicianData?['isVerified'] == true)
              Icon(
                Icons.verified_sharp,
                size: 22,
                color: Colors.green,
              ),
          ],
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where(
              'recipientId',
              isEqualTo: FirebaseAuth.instance.currentUser!.uid,
            )
                .where('read', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none, size: 35,),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const TechnicianNotificationScreen(),
                        ),
                      );
                    },
                  ),

                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          SizedBox(width: 4,),
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 20,
                backgroundImage:
                profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
                child: profileUrl.isEmpty ? Icon(Icons.person) : null,
              ),
            ),
          ),
          SizedBox(width: 10,),

        ],
      ),
      endDrawer: _buildDrawer(context),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // ONLINE STATUS
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('technicians')
                  .doc(user!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                bool online = false;
                if (snapshot.hasData) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  online = data?['isOnline'] ?? false;
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Text(
                              'Current Status',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 5),
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  margin: EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: online ? Colors.green : Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Text(
                                  online ? "Available" : "Unavailable",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: online ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: online,
                          onChanged: (val) => _updateOnlineStatus(val),
                          activeThumbColor: Colors.green,
                          activeTrackColor: Colors.green.withOpacity(0.5),
                          inactiveThumbColor: Colors.orange,
                          inactiveTrackColor: Colors.orange.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 20),

            if (_technicianData != null) technicianHeader(_technicianData!),
            SizedBox(height: 10),

           SizedBox(height: 20),

            Text(
              "Work Showcases",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            ShowcaseFeedWidget(),
          ],
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    final userName = _technicianData?['name'] ?? 'Technician';
    final userPhone = _technicianData?['phone'] ?? '';
    final userProfileImage = _technicianData?['profilePic'] ?? '';
    final isVerified = _technicianData?['isVerified'] ?? false;
    final rating = _technicianData?['avgRating'] ?? 0.0;
    final location = _technicianData?['location'] ?? 'Unknown';
    final serviceType = _technicianData?['service'] ?? '';

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ===== PROFILE HEADER =====
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.blue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: userProfileImage.isNotEmpty
                            ? NetworkImage(userProfileImage)
                            : null,
                        child: userProfileImage.isEmpty
                            ? Icon(Icons.person)
                            : null,
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Text(
                                userName,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(serviceType, style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          Text(
                            userPhone,
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  /// ===== RATING & VERIFICATION =====
                  Row(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.verified,
                            color: isVerified ? Colors.green : Colors.grey,
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          Text(
                            isVerified ? "Verified" : "Unverified",
                            style: TextStyle(
                              color: isVerified ? Colors.white : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 12),
                      Row(
                        children: [
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 6),
                          Row(children: _buildStars(rating)),
                        ],
                      ),

                    ],
                  ),

                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white70, size: 16),
                      SizedBox(width: 4),
                      Text(location, style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                  SizedBox(height: 6),


                ],
              ),
            ),

            SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("My Profile"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TechnicianProfileScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: Icon(Icons.edit),
              title: Text("Edit Profile"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditTechnicianProfileScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: Icon(Icons.history),
              title: Text("Job History"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TechnicianJobHistoryScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: Icon(Icons.history),
              title: Text("Privacy Policy"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PrivacyPolicy(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("Terms and Condition"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const TermsAndConditions(),
                  ),
                );
              },
            ),





            ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.red),
              title: Text(
                "Delete Account",
                style: TextStyle(color: Colors.red),
              ),
              onTap: _showDeleteAccountDialog,
            ),

            Spacer(),
            Divider(),

            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text("Logout"),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => WelcomeScreen()),
                      (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget technicianHeader(Map<String, dynamic> data) {
    final serviceType = data['service'] ?? '';
    final areaOfOperation = data['location'] ?? '';
    final years = data['yearsOfExperience'] ?? 0;
    final isVerified = data['isVerified'] ?? false;
    final isSuspended = data['isSuspended'] ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: [
                  Text("My Service: ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300),),
                  Text(
                    serviceType,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text("Area of Operation: ", style: TextStyle(fontWeight: FontWeight.w100),),
              Text("$areaOfOperation", style: TextStyle(fontWeight: FontWeight.bold),),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text("Experience: "),
              Text("$years years", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Chip(
                label: Text(isSuspended ? "Suspended" : "Active"),
                backgroundColor:
                isSuspended ? Colors.red.shade100 : Colors.green.shade100,
              ),
              SizedBox(width: 10),
              Chip(
                label: Text(
                  isVerified ? 'Verified ✅' : 'Pending Verification ⏳',
                  style: TextStyle(
                    color: isVerified ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  List<Widget> _buildStars(double rating) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    List<Widget> stars = [];

    for (int i = 0; i < fullStars; i++) {
      stars.add(const Icon(Icons.star, size: 16, color: Colors.amber));
    }

    if (hasHalfStar) {
      stars.add(const Icon(Icons.star_half, size: 16, color: Colors.amber));
    }

    return stars;
  }
}