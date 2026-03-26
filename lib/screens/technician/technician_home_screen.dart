import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kwikpro/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../onboarding/welcome_screen.dart';



class TechnicianHomeScreen extends ConsumerStatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  ConsumerState<TechnicianHomeScreen> createState() =>
      _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends ConsumerState<TechnicianHomeScreen> {
  StreamSubscription<Position>? _positionStream;
  final user = FirebaseAuth.instance.currentUser;

  bool isOnline = false; // Local state for the switch

  /// Toggle online/offline and optionally stream location
  void _updateOnlineStatus(bool value) async {
    setState(() {
      isOnline = value;
    });

    if (user == null) return;

    if (value) {
      // START LOCATION STREAM
      _positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
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
      // STOP LOCATION STREAM
      await _positionStream?.cancel();
      _positionStream = null;

      // update offline in Firestore
      await FirebaseFirestore.instance
          .collection('technicians')
          .doc(user!.uid)
          .update({
        'isOnline': false,
      });
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: user == null
            ? Text("Technician")
            : StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('technicians')
              .doc(user!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Row(
                children: [
                  CircleAvatar(radius: 25, child: Icon(Icons.person)),
                  SizedBox(width: 10),
                  Text('Loading...'),
                  Spacer(),
                  // Switch still uses local isOnline
                  Switch(
                    value: isOnline,
                    onChanged: (val) {
                      _updateOnlineStatus(val);
                    },
                  ),
                ],
              );
            }

            final doc = snapshot.data!;
            final data = doc.data() as Map<String, dynamic>?;

            final name = data?['name'] ?? 'Technician';
            final serviceType = data?['service'] ?? 'Technician';
            final profileUrl = data?['profilePic'] ?? '';

            return Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: profileUrl.isNotEmpty
                      ? NetworkImage(profileUrl)
                      : null,
                  child: profileUrl.isEmpty ? Icon(Icons.person, size: 30) : null,
                ),
                SizedBox(width: 10),
                Text("$name $serviceType",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Spacer(),
                Switch(
                  value: isOnline,
                  activeThumbColor: Colors.green,
                  onChanged: (val) {
                    _updateOnlineStatus(val);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              try {
                await ref.read(authServiceProvider).signOut();
                ref.read(authProvider.notifier).logout();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WelcomeScreen(),
                  ),
                      (route) => false,
                );
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text("Error logging out $e")));
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pending Jobs
            Text('Pending Jobs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Card(
              child: Row(
                children: [Text("Jobs")],
              ),
            ),
            SizedBox(height: 20),
            // Ratings & Reviews
            Text('Ratings & Reviews',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

          ],
        ),
      ),

    );
  }
}