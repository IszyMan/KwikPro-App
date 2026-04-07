import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kwikpro/core/app_card.dart';
import 'package:kwikpro/core/status_badge.dart';
import 'package:kwikpro/core/text_styles.dart';
import '../onboarding/welcome_screen.dart';
import 'TechnicianDetailsScreen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String searchQuery = '';
  bool? filterVerified;
  bool? filterSuspended;

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("All KwikPro Technicians"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                      (route) => false,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error signing out: $e")),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(),
          _buildFilterChips(),
          Expanded(child: _buildTechniciansList()),
        ],
      ),
    );
  }

  /// Search Field Widget
  Widget _buildSearchField() {
    return Padding(
      padding: EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "search by name, service or location..",
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value.toLowerCase().trim();
          });
        },
      ),
    );
  }

  /// Filter Chips Widget
  Widget _buildFilterChips() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          FilterChip(
            label: Text("Verified"),
            selected: filterVerified == true,
            onSelected: (value) {
              setState(() {
                filterVerified = value ? true : null;
              });
            },
          ),
          SizedBox(width: 8),
          FilterChip(
            label: Text("Not Verified"),
            selected: filterVerified == false,
            onSelected: (value) {
              setState(() {
                filterVerified = value ? false : null;
              });
            },
          ),
          SizedBox(width: 8),
          FilterChip(
            label: Text("Active"),
            selected: filterSuspended == false,
            onSelected: (value) {
              setState(() {
                filterSuspended = value ? false : null;
              });
            },
          ),
          SizedBox(width: 8),
          FilterChip(
            label: Text("Suspended"),
            selected: filterSuspended == true,
            onSelected: (value) {
              setState(() {
                filterSuspended = value ? true : null;
              });
            },
          ),
        ],
      ),
    );
  }

  /// Technicians List Widget
  Widget _buildTechniciansList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('technicians').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No Technician found'));
        }

        final techs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          final name = (data['name'] ?? '').toString().toLowerCase().trim();
          final location = (data['location'] ?? '').toString().toLowerCase().trim();
          final serviceType = (data['service'] ?? '').toString().toLowerCase().trim();
          final isSuspended = data['isSuspended'] ?? false;
          final isVerified = data['isVerified'] ?? false;

          final matchesSearch = searchQuery.isEmpty ||
              name.contains(searchQuery) ||
              location.contains(searchQuery) ||
              serviceType.contains(searchQuery);

          final matchesVerified = filterVerified == null || isVerified == filterVerified;
          final matchesSuspended = filterSuspended == null || isSuspended == filterSuspended;

          return matchesSearch && matchesVerified && matchesSuspended;
        }).toList();

        return ListView.builder(
          itemCount: techs.length,
          itemBuilder: (context, index) {
            final doc = techs[index];
            final data = doc.data() as Map<String, dynamic>;

            return _buildTechnicianItem(doc.id, data);
          },
        );
      },
    );
  }

  /// Single Technician Card Widget
  Widget _buildTechnicianItem(String docId, Map<String, dynamic> data) {
    final name = data['name'] ?? 'No name';
    final profilePic = data['profilePic'] ?? '';
    final location = data['location'] ?? '';
    final serviceType = data['service'] ?? '';
    final isSuspended = data['isSuspended'] ?? false;
    final isVerified = data['isVerified'] ?? false;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TechnicianDetailsScreen(
              docId: docId,
              data: data,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: AppCard(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey,
                  backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                  child: profilePic.isEmpty
                      ? Text(name[0].toUpperCase(), style: TextStyle(fontSize: 18))
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.heading),
                      SizedBox(height: 2),
                      Text(serviceType, style: AppTextStyles.subheading),
                      SizedBox(height: 2),
                      Text(location, style: AppTextStyles.body),
                      SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          StatusBadge(
                            label: isVerified ? "Verified" : "Not Verified",
                            color: isVerified ? Colors.green : Colors.yellow,
                            icon: Icons.verified,
                          ),
                          SizedBox(width: 5),
                          StatusBadge(
                            label: isSuspended ? "Suspended" : "Active",
                            color: isSuspended ? Colors.red : Colors.green,
                            icon: isSuspended ? Icons.block : Icons.check_circle,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}