import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kwikpro/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../onboarding/welcome_screen.dart';

// Mock Data
final List<Map<String, dynamic>> pendingJobs = [
  {
    'user': 'Ade',
    'service': 'AC Repair',
    'location': 'Yaba, Lagos',
    'distance': '2.3 km',
    'description': 'AC not cooling'
  },
  {
    'user': 'Tunde',
    'service': 'Fridge Repair',
    'location': 'Ikeja, Lagos',
    'distance': '4.1 km',
    'description': 'Fridge making noise'
  },
];

final List<Map<String, dynamic>> completedJobs = [
  {'service': 'Plumbing', 'date': '22 Mar', 'price': 5000, 'rating': 5},
  {'service': 'Electrician', 'date': '20 Mar', 'price': 3000, 'rating': 4},
];

final List<Map<String, dynamic>> reviews = [
  {'user': 'Mary', 'rating': 5, 'comment': 'Great work, punctual.'},
  {'user': 'John', 'rating': 4, 'comment': 'Reasonable price, fixed quickly.'},
];

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

  // BottomNav
  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
                Text(name,
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
            Column(
              children: reviews
                  .map((review) => Card(
                margin: EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  title: Text(review['user']),
                  subtitle: Text(review['comment']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                        review['rating'],
                            (index) =>
                            Icon(Icons.star, color: Colors.orange, size: 16)),
                  ),
                ),
              ))
                  .toList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}