import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kwikpro/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../onboarding/welcome_screen.dart';
import 'package:intl/intl.dart';

class TechnicianHomeScreen extends ConsumerStatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  ConsumerState<TechnicianHomeScreen> createState() =>
      _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends ConsumerState<TechnicianHomeScreen> {
  StreamSubscription<Position>? _positionStream;
  final user = FirebaseAuth.instance.currentUser;

  Timer? timer;
  Map<String, Timer> requestTimers = {};
  Map<String, int> countdowns = {};

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
    // Stop the timer when request is handled
    requestTimers[requestId]?.cancel();
  }

  void startCountdown(String requestId) {
    countdowns[requestId] = 30; // initial 30s
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
          // Update Firestore status automatically
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

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('technicians')
              .doc(user!.uid)
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return SizedBox();

            final data = snapshot.data!.data() as Map<String, dynamic>?;
            final name = data?['name'] ?? 'Technician';
            final serviceType = data?['service'] ?? '';
            final yearsOfExperience = data?['yearsOfExperience'] ?? '';
            final profileUrl = data?['profilePic'] ?? '';
            final isVerified = data?['isVerified'] ?? false;
            final isSuspended = data?['isSuspended'] ?? false;



            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    '$name  $serviceType ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),

                Text('Experience: $yearsOfExperience years +'),

                Text(
                  isSuspended ? 'Suspended' : 'Active',
                  style: TextStyle(
                    color: isSuspended ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isVerified ? 'Verified ✅' : 'Pending Verification ⏳',
                  style: TextStyle(
                    color: isVerified ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                  profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
                  child: profileUrl.isEmpty ? Icon(Icons.person) : null,
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              ref.read(authProvider.notifier).logout();
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                      (route) => false);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // 🔹 ONLINE STATUS
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
                            Text('Current Status',style: TextStyle(fontWeight: FontWeight.bold),),
                            SizedBox(height: 5,),
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

            // 🔹 INCOMING JOB REQUESTS
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

                // Start countdown for new requests
                for (var doc in requests) {
                  if (!countdowns.containsKey(doc.id)) {
                    startCountdown(doc.id);
                  }
                }

                return Column(
                  children: requests.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final countdown = countdowns[doc.id] ?? 30;
                    final isCounting = countdown > 0;

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(
                            '${data['service']} Needed'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (data['description'] != null)
                              Text(data['description']),
                             SizedBox(height: 4,),
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
                                  ? () =>
                                  _updateStatus(doc.id, "accepted")
                                  : null,
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: isCounting
                                  ? () =>
                                  _updateStatus(doc.id, "rejected")
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

            // 🔹 PREVIOUS REQUESTS
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
}