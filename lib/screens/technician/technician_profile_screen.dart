import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kwikpro/screens/technician/technician_job_history_screen.dart';

import '../user/privacy_policy.dart';
import '../user/terms_and_conditions.dart';
import 'edit_technician_profile_screen.dart';


class TechnicianProfileScreen extends StatefulWidget {
  const TechnicianProfileScreen({super.key});

  @override
  State<TechnicianProfileScreen> createState() =>
      _TechnicianProfileScreenState();
}

class _TechnicianProfileScreenState extends State<TechnicianProfileScreen> {

  Stream<DocumentSnapshot<Map<String, dynamic>>> _techStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('technicians')
        .doc(uid)
        .snapshots();
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

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;

    await FirebaseFirestore.instance
        .collection('technicians')
        .doc(uid)
        .delete();

    await user.delete();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _techStream(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() ?? {};

          final name = data['name'] ?? 'Technician';
          final phone = data['phone'] ?? '';
          final profilePic = data['profilePic'] ?? '';
          final category = data['service'] ?? 'General';
          final location = data['location'] ?? 'Unknown';
          final rating = (data['avgRating'] ?? 0).toDouble();
          final isVerified = data['isVerified'] ?? false;

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [

                  /// ================= HEADER (USER PROFILE STYLE)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    color: Colors.blue,
                    child: Column(
                      children: [

                        CircleAvatar(
                          radius: 40,
                          backgroundImage: profilePic.isNotEmpty
                              ? NetworkImage(profilePic)
                              : null,
                          child: profilePic.isEmpty
                              ? const Icon(Icons.person,
                              size: 40, color: Colors.white)
                              : null,
                        ),

                        const SizedBox(height: 10),

                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              category,
                              style: const TextStyle(color: Colors.white70),
                            ),

                            SizedBox(width: 5,),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on,
                                    size: 16, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  location,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 5),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified,
                              color: isVerified
                                  ? Colors.green
                                  : Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isVerified ? "Verified" : "Unverified",
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                  ),

                  const SizedBox(height: 10),

                  /// ================= BODY (FULL SCROLL)
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text("Edit Profile"),
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
                    leading: const Icon(Icons.work),
                    title: const Text("Job History"),
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
                    leading: const Icon(Icons.star),
                    title: const Text("Ratings & Reviews"),
                    onTap: () {},
                  ),

                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: const Text("Privacy Policy"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicy(),
                        ),
                      );
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.rule),
                    title: const Text("Terms and Conditions"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TermsAndConditions(),
                        ),
                      );
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.delete_forever,
                        color: Colors.red),
                    title: const Text(
                      "Delete Account",
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: _showDeleteDialog,
                  ),

                  const Divider(),

                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text("Logout"),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!mounted) return;
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}