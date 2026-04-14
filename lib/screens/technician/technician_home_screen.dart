import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kwikpro/screens/technician/edit_technician_profile_screen.dart';
import 'package:kwikpro/screens/technician/technician_job_history_screen.dart';
import 'package:kwikpro/screens/technician/technician_notification_screen.dart';
import '../onboarding/welcome_screen.dart';
import 'package:intl/intl.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchTechnicianData();
    saveFcmToken();
    _setupNotifications();
  }

  void _setupNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? '';
      final body = message.notification?.body ?? '';

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$title\n$body")),
      );
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


  Future<void> saveFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();

    if (token != null) {
      await FirebaseFirestore.instance
          .collection('technicians')
          .doc(user.uid)
          .update({
        'fcmToken': token,
      });

      debugPrint("FCM Token saved: $token");
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

  void _updateStatus(String requestId, String status) async {
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .update({"status": status});
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
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TechnicianNotificationScreen(),
                ),
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
                                  online ? "Online" : "Offline",
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

            //f INCOMING JOB REQUESTS
            Text('Incoming Job Requests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .where('technicianId', isEqualTo: user!.uid)
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final requests = snapshot.data!.docs;

                if (requests.isEmpty) return Text("No incoming requests");

                for (var doc in requests) {
                  if (!countdowns.containsKey(doc.id)) startCountdown(doc.id);
                }

                return Column(
                  children: requests.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final countdown = countdowns[doc.id] ?? 30;
                    final isCounting = countdown > 0;

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text('${data['service']} Needed'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (data['description'] != null)
                              Text(data['description']),
                            SizedBox(height: 4),
                            Text('📍 ${data['serviceLocationAddress']}'),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.timer, size: 14, color: Colors.blue),
                                SizedBox(width: 4),
                                Text(
                                  isCounting
                                      ? 'Respond within $countdown s'
                                      : 'Time expired',
                                  style: TextStyle(
                                    color: isCounting ? Colors.blue : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.check, color: Colors.green),
                              onPressed: isCounting
                                  ? () => _updateStatus(doc.id, "accepted")
                                  : null,
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: isCounting
                                  ? () => _updateStatus(doc.id, "rejected")
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            SizedBox(height: 20),

            // PREVIOUS REQUESTS
            Text('Previous Requests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .where('technicianId', isEqualTo: user!.uid)
                  .where('status',
                  whereIn: ['accepted', 'rejected', 'declined'])
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final prevRequests = snapshot.data!.docs;

                if (prevRequests.isEmpty) return Text("No previous requests");

                return Column(
                  children: prevRequests.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] ?? '';

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text('${data['service']} Needed'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (data['createdAt'] != null)
                              Text(formatDate(data['createdAt'])),
                            Text(data['description']),
                            SizedBox(height: 4),
                            Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: getStatusColor(status),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
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
    final rating = _technicianData?['rating'] ?? 0.0;
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
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      SizedBox(width: 4),
                      Text("$rating Rating", style: TextStyle(color: Colors.white)),

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
              leading: Icon(Icons.person),
              title: Text("My Profile"),
              onTap: () {},
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
              leading: Icon(Icons.star),
              title: Text("Reviews"),
              onTap: () {},
            ),

            ListTile(
              leading: Icon(Icons.settings),
              title: Text("Settings"),
              onTap: () {},
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
}