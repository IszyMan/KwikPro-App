import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:kwikpro/providers/auth_provider.dart';
import 'package:kwikpro/screens/onboarding/welcome_screen.dart';

import '../../widgets/service_card.dart';

import 'package:flutter/services.dart';
import 'package:kwikpro/screens/user/edit_user_profile_screen.dart';
import 'package:kwikpro/screens/user/user_job_history_screen.dart';

class UserHomeScreen extends ConsumerStatefulWidget {
  const UserHomeScreen({super.key});

  @override
  ConsumerState<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends ConsumerState<UserHomeScreen> {
  String name = '';
  String profilePic = '';
  String location = '';
  double? userLat;
  double? userLng;

  final GlobalKey<ScaffoldState> _scaffoldKey =
  GlobalKey<ScaffoldState>();

  String? _verificationId;

  String _searchQuery = '';


  final services = [
    "Electrician",
    "Plumber",
    "Fridge Repairer",
    "AC Repairer",
    "Painter",
    "Generator Repairer",
  ];


  @override
  void initState() {
    super.initState();
    _loadUser();
  }


  Future<void> _showDeleteAccountDialog() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "Deleting your account will permanently remove your profile, requests and account data.\n\nThis action cannot be undone.",
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

      verificationCompleted: (
          PhoneAuthCredential credential,
          ) async {},

      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message ?? "OTP failed",
            ),
          ),
        );
      },

      codeSent: (
          String verificationId,
          int? resendToken,
          ) {
        _verificationId = verificationId;
        _showOTPDialog();
      },

      codeAutoRetrievalTimeout: (
          String verificationId,
          ) {
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

      // RE-AUTHENTICATE
      await user.reauthenticateWithCredential(
        credential,
      );

      final uid = user.uid;

      // DELETE USER DOCUMENT
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .delete();

      // DELETE USER REQUESTS
      final requests = await FirebaseFirestore.instance
          .collection('requests')
          .where('userId', isEqualTo: uid)
          .get();

      for (final doc in requests.docs) {
        await doc.reference.delete();
      }

      // DELETE NOTIFICATIONS
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .get();

      for (final doc in notifications.docs) {
        await doc.reference.delete();
      }

      // DELETE REVIEWS
      final reviews = await FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', isEqualTo: uid)
          .get();

      for (final doc in reviews.docs) {
        await doc.reference.delete();
      }

      // DELETE FIREBASE AUTH ACCOUNT
      await user.delete();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const WelcomeScreen(),
        ),
            (route) => false,
      );

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? "Authentication failed",
          ),
        ),
      );
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? "Something went wrong",
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Delete failed: $e",
          ),
        ),
      );
    }
  }



  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      //print("DEBUG LAT: $lat, LNG: $lng");

      final placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isEmpty) return "Unknown";

      final place = placemarks.first;

      return [
        place.subLocality,
        place.locality,
        place.subAdministrativeArea,
        place.administrativeArea,
        place.country
      ].firstWhere(
            (e) => e != null && e.isNotEmpty,
        orElse: () => "Unknown",
      )!;
    } catch (e) {
      print("GEOCODING ERROR: $e");
      return "Unknown";
    }
  }



  void _loadUser() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    final data = doc.data();

    String fetchedLocation = data?['currentAddress'] ?? 'Unknown';
    double? lat = data?['lat'];
    double? lng = data?['lng'];

    setState(() {
      name = data?['name'] ?? 'User';
      profilePic = data?['profilePic'] ?? '';
      location = fetchedLocation;
      userLat = lat;
      userLng = lng;
    });

    //  Now reverse geocode if lat/lng exists
    if (lat != null && lng != null) {
      final newAddress = await _getAddressFromLatLng(lat, lng);

      if (newAddress != "Unknown") {
        setState(() {
          location = newAddress;
        });
      }

      // (optional) update firestore with fresh address
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        'currentAddress': newAddress,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredServices = services.where((service) {
      return service.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _buildDrawer(context),
      appBar: AppBar(
        title: Column(

            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage:
                    profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                    child: profilePic.isEmpty ? Icon(Icons.person, size: 20) : null,
                  ),
                  SizedBox(width: 10),
                  Text('Hi, $name'),
                ],
              ),

              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      location,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    SizedBox(width: 6),

                    // Future: Change button
                    GestureDetector(
                      onTap: () {
                        // we’ll implement this next step
                      },
                      child: Text(
                        "Change",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
        actions: [
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundImage:
                profilePic.isNotEmpty
                    ? NetworkImage(profilePic)
                    : null,
                child: profilePic.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Header Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "What help do you need today?",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),

                // Search Field
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search for services (e.g plumber, electrician)",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ],
            ),
          ),


          // Services Cards
          Expanded(

            child: GridView.builder(

              padding: const EdgeInsets.all(16),
              itemCount: filteredServices.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final service = filteredServices[index];

                return ServiceCard(service: service);
              },
            ),
          )
        ],
      ),
    );
  }


  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [

            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.blue,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage:
                    profilePic.isNotEmpty
                        ? NetworkImage(profilePic)
                        : null,
                    child: profilePic.isEmpty
                        ? const Icon(Icons.person, size: 40)
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

                  const SizedBox(height: 5),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // EDIT PROFILE
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Edit Profile"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const EditUserProfileScreen(),
                  ),
                );
              },
            ),

            // JOB HISTORY
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("Job History"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const UserJobHistoryScreen(),
                  ),
                );
              },
            ),

            // DELETE ACCOUNT
            ListTile(
              leading: const Icon(
                Icons.delete_forever,
                color: Colors.red,
              ),
              title: const Text(
                "Delete Account",
                style: TextStyle(color: Colors.red),
              ),
              onTap: _showDeleteAccountDialog,
            ),

            const Spacer(),

            const Divider(),

            // LOGOUT
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text("Logout"),
              onTap: () async {
                try {
                  await ref
                      .read(authServiceProvider)
                      .signOut();

                  ref
                      .read(authProvider.notifier)
                      .logout();

                  if (!mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const WelcomeScreen(),
                    ),
                        (route) => false,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        "Logout failed: $e",
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}