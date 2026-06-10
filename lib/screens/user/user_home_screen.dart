import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:kwikpro/providers/auth_provider.dart';
import 'package:kwikpro/screens/onboarding/welcome_screen.dart';
import 'package:kwikpro/screens/user/privacy_policy.dart';
import 'package:kwikpro/screens/user/terms_and_conditions.dart';
import 'package:kwikpro/screens/user/user_notification_screen.dart';
import '../../services/notification_service.dart';
import '../../widgets/service_card.dart';
import 'package:flutter/services.dart';
import 'package:kwikpro/screens/user/edit_user_profile_screen.dart';
import 'package:kwikpro/screens/user/user_job_history_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
    NotificationService.saveFcmToken(collection: 'users');
    NotificationService.setupForegroundNotifications(context);
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


  Future<List<dynamic>> searchLocations(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search"
            "?q=${Uri.encodeComponent(query + ' lagos nigeria')}"
            "&format=json"
            "&addressdetails=1"
            "&limit=8",
      );

      final response = await http.get(url, headers: {
        "User-Agent": "KwikProApp/1.0 (your_email@example.com)",
      });

      if (response.statusCode != 200) {
        print("Search error: ${response.body}");
        return [];
      }

      final data = json.decode(response.body);

      if (data is List) {
        return data;
      }

      return [];
    } catch (e) {
      print("SEARCH ERROR: $e");
      return [];
    }
  }


  void _openLocationPicker() {
    final controller = TextEditingController();
    List<dynamic> results = [];
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Choose Location",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Search Lekki, Ajah, Ikeja...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) async {
                      setModalState(() {
                        loading = true;
                      });

                      results = await searchLocations(value);

                      setModalState(() {
                        loading = false;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  if (loading)
                    CircularProgressIndicator()
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final item = results[index];

                          final displayName = item["display_name"] ?? "Unknown";

                          return ListTile(
                            leading: Icon(Icons.location_on),
                            title: Text(displayName),
                            onTap: () async {
                              final lat = double.parse(item["lat"]);
                              final lng = double.parse(item["lon"]);

                              Navigator.pop(context);

                              await _updateUserLocation(lat, lng);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateUserLocation(double lat, double lng) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final address = await _getAddressFromLatLng(lat, lng);

    setState(() {
      userLat = lat;
      userLng = lng;
      location = address;
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({
      'lat': lat,
      'lng': lng,
      'currentAddress': address,
    });
  }



  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      final url = Uri.parse(
        "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1",
      );

      final response = await http.get(
        url,
        headers: {
          // REQUIRED by Nominatim policy
          "User-Agent": "KwikProApp/1.0 (your_email@example.com)",
        },
      );

      if (response.statusCode != 200) {
        print("OSM ERROR: ${response.body}");
        return "Unknown";
      }

      final data = json.decode(response.body);

      final address = data["address"];

      final suburb = address?["suburb"] ??
          address?["neighbourhood"] ??
          address?["residential"] ??
          "";

      final city = address?["city"] ??
          address?["town"] ??
          address?["village"] ??
          address?["municipality"] ??
          "";

      final district = address?["county"] ??
          address?["state_district"] ??
          "";

      final state = address?["state"] ?? "";

      String result = "";

      if (suburb.isNotEmpty) {
        result += suburb;
      }

      if (district.isNotEmpty) {
        result += result.isEmpty ? district : ", $district";
      }

      if (state.isNotEmpty) {
        result += result.isEmpty ? state : ", $state";
      }

      return result.isNotEmpty ? result : "Unknown";

    } catch (e) {
      print("OSM GEOCODING ERROR: $e");
      return "Unknown";
    }
  }



  void _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!doc.exists) {
      print("User document does not exist");
      return;
    }

    final data = doc.data();

    double? lat = data?['lat'];
    double? lng = data?['lng'];

    print("Testing reverse geocode...");
    print("Lat: $lat");
    print("Lng: $lng");

    //  FIRST SET BASIC USER DATA
    setState(() {
      name = data?['name'] ?? 'User';
      profilePic = data?['profilePic'] ?? '';
      location = data?['currentAddress'] ?? 'Unknown';
      userLat = lat;
      userLng = lng;
    });

    //  SAFE CHECK BEFORE GEOCODING
    if (lat == null || lng == null) {
      print("No coordinates found, skipping geocoding");
      return;
    }

    try {
      final newAddress = await _getAddressFromLatLng(lat, lng);

      print("ADDRESS FOUND: $newAddress");

      if (newAddress.isNotEmpty && newAddress != "Unknown") {
        setState(() {
          location = newAddress;
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({
          'currentAddress': newAddress,
        });
      }
    } catch (e) {
      print("Reverse geocode error: $e");
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
                      onTap: _openLocationPicker,
                      child: Text(
                        "Edit",
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
                          const UserNotificationScreen(),
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

            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text("Privacy Policy"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const PrivacyPolicy(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.rule),
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