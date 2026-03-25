import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwikpro/providers/auth_provider.dart';
import 'package:kwikpro/screens/onboarding/welcome_screen.dart';
import 'package:kwikpro/widgets/technician_card.dart';

import '../../models/technician_model.dart';

class UserHomeScreen extends ConsumerStatefulWidget {
  const UserHomeScreen({super.key});

  @override
  ConsumerState<UserHomeScreen> createState() =>
      _UserHomeScreenState();
}

class _UserHomeScreenState extends ConsumerState<UserHomeScreen> {
  String name = '';
  String profilePic = '';

  @override
  void initState() {
    super.initState();

    // Fetch user info
    _loadUser();
  }

  void _loadUser() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    final data = doc.data();

    setState(() {
      name = data?['name'] ?? 'User';
      profilePic = data?['profilePic'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage:
              profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
              child:
              profilePic.isEmpty ? Icon(Icons.person, size: 20) : null,
            ),
            SizedBox(width: 10),
            Text('Hi, $name'),
          ],
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
                      builder: (_) => const WelcomeScreen()),
                      (route) => false,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error logging out $e")));
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('technicians')
              .where('isOnline', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text("No technicians online"));
            }

            final technicians = snapshot.data!.docs;

            return ListView.builder(
              itemCount: technicians.length,
              itemBuilder: (context, index) {
                final data = technicians[index].data() as Map<String, dynamic>;

                return TechnicianCard(
                  technician: TechnicianModel.fromMap(data),
                );
              },
            );
          },
        ),
      ),
    );
  }
}