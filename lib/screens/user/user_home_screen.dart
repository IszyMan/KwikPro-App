import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/technician_model.dart';
import '../../services/location_service.dart';
import 'package:kwikpro/providers/auth_provider.dart';
import 'package:kwikpro/screens/onboarding/welcome_screen.dart';
import 'package:kwikpro/screens/user/privacy_policy.dart';
import 'package:kwikpro/screens/user/terms_and_conditions.dart';
import 'package:kwikpro/screens/user/user_notification_screen.dart';
import '../../services/notification_service.dart';
import 'package:flutter/services.dart';
import 'package:kwikpro/screens/user/edit_user_profile_screen.dart';
import 'package:kwikpro/screens/user/user_job_history_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/firestore_service.dart';
import 'package:kwikpro/screens/user/all_services_screen.dart';
import 'package:kwikpro/screens/user/all_nearby_technicians_screen.dart';
import '../../widgets/user_home/recommended_widget.dart';

import '../../widgets/user_home/nearby_technicians_widget.dart';
import '../../widgets/user_home/popular_services_widget.dart';
import '../../widgets/user_home/recently_booked_widget.dart';
import '../../widgets/user_home/user_home_app_bar.dart';
import '../../widgets/user_home/user_home_drawer.dart';
import 'all_recommended_screen.dart';


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

  List<TechnicianModel> nearbyTechnicians = [];
  List<TechnicianModel> recentlyBookedTechnicians = [];
  List<TechnicianModel> recommendedTechnicians = [];

  final FirestoreService _firestoreService = FirestoreService();

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 1));
      _loadCurrentLocation();
    });
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

    final address = await LocationService.reverseGeocode(lat, lng);

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


  Future<void> _loadCurrentLocation() async {
    setState(() {
      location = "Detecting location...";
    });

    final result = await LocationService.getCurrentLocation();

    if (!mounted) return;

    //  CASE 1: location failed
    if (result == null) {
      setState(() {
        location = "Location not available. Tap to set manually.";
      });
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    if (!mounted) return;

    final locationChanged =
        userLat != result['lat'] || userLng != result['lng'];

    setState(() {
      location = result['address'];
      userLat = result['lat'];
      userLng = result['lng'];
    });

    if (locationChanged) {
      await _loadNearbyTechnicians();
      await _loadRecentlyBookedTechnicians();
      await _loadRecommendedTechnicians();
    }

   // Save location in the background.
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({
      'lat': result['lat'],
      'lng': result['lng'],
      'currentAddress': result['address'],
    });
  }


  Future<void> _loadNearbyTechnicians() async {
    if (userLat == null || userLng == null) return;

    try {
      final technicians =
      await _firestoreService.getNearbyTechnicians(
        userLat: userLat!,
        userLng: userLng!,
        limit: 10,
      );

      if (!mounted) return;

      setState(() {
        nearbyTechnicians = technicians;
      });
    } catch (e) {
      debugPrint("Nearby technician error: $e");
    }
  }


  Future<void> _loadRecentlyBookedTechnicians() async {
    if (userLat == null || userLng == null) return;

    try {
      final technicians =
      await _firestoreService.getRecentlyBookedTechnicians(
        userLat: userLat!,
        userLng: userLng!,
      );

      print("Recently booked: ${technicians.length}");

      if (!mounted) return;

      setState(() {
        recentlyBookedTechnicians = technicians;
      });
    } catch (e) {
      print("Recently booked error: $e");
    }
  }

  Future<void> _loadRecommendedTechnicians() async {
    if (userLat == null || userLng == null) return;

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final technicians =
      await _firestoreService.getRecommendedTechnicians(
        userId: uid,
        userLat: userLat!,
        userLng: userLng!,
      );

      if (!mounted) return;

      setState(() {
        recommendedTechnicians = technicians;
      });
    } catch (e) {
      debugPrint("Recommendation error: $e");
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

    //  FIRST SET BASIC USER DATA
    setState(() {
      name = data?['name'] ?? 'User';
      profilePic = data?['profilePic'] ?? '';

      location = data?['currentAddress'] ?? '';

      userLat = (data?['lat'] as num?)?.toDouble();
      userLng = (data?['lng'] as num?)?.toDouble();

    });

    // Load nearby technicians immediately using saved location.
    if (userLat != null && userLng != null) {
      _loadNearbyTechnicians();
      _loadRecentlyBookedTechnicians();
      _loadRecommendedTechnicians();
    }


  }

  @override
  Widget build(BuildContext context) {
    final filteredServices = services.where((service) {
      return service.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: UserHomeDrawer(
        name: name,
        profilePic: profilePic,
        location: location,

        onEditProfile: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EditUserProfileScreen(),
            ),
          );
        },

        onJobHistory: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const UserJobHistoryScreen(),
            ),
          );
        },

        onPrivacyPolicy: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PrivacyPolicy(),
            ),
          );
        },

        onTerms: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TermsAndConditions(),
            ),
          );
        },

        onDeleteAccount: _showDeleteAccountDialog,

        onLogout: () async {
          try {
            await ref.read(authServiceProvider).signOut();

            ref.read(authProvider.notifier).logout();

            if (!mounted) return;

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const WelcomeScreen(),
              ),
                  (_) => false,
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Logout failed: $e")),
            );
          }
        },
      ),

      // ================= STATIC APP BAR =================
      appBar: UserHomeAppBar(
        name: name,
        location: location,
        profilePic: profilePic,
        searchQuery: _searchQuery,

        onLocationTap: _openLocationPicker,

        onNotificationTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const UserNotificationScreen(),
            ),
          );
        },

        onProfileTap: () {
          _scaffoldKey.currentState?.openEndDrawer();
        },

        onSearchChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),

      // ================= SINGLE SCROLL BODY =================
      body: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [

          // ================= SERVICES =================
          PopularServicesWidget(
            services: filteredServices,
            location: location,
            lat: userLat,
            lng: userLng,
            onSeeAll: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AllServicesScreen(
                    services: services,
                    location: location,
                    lat: userLat,
                    lng: userLng,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          NearbyTechniciansWidget(
            technicians: nearbyTechnicians,
            userLat: userLat,
            userLng: userLng,
            onSeeAll: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AllNearbyTechniciansScreen(
                    technicians: nearbyTechnicians,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          RecentlyBookedWidget(
            technicians: recentlyBookedTechnicians,
            userLat: userLat,
            userLng: userLng,
            onSeeAll: () {
              // We'll create the See All screen next.
            },
          ),


          const SizedBox(height: 20),

          RecommendedWidget(
            technicians: recommendedTechnicians,
            userLat: userLat,
            userLng: userLng,
            onSeeAll: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AllRecommendedScreen(
                    technicians: recommendedTechnicians,
                  ),
                ),
              );
            },
          ),


        ],
      ),
    );
  }



}