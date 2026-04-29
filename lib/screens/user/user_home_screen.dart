import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:kwikpro/providers/auth_provider.dart';
import 'package:kwikpro/screens/onboarding/welcome_screen.dart';

import '../../widgets/service_card.dart';

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



  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      print("DEBUG LAT: $lat, LNG: $lng");

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
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              try {
                await ref.read(authServiceProvider).signOut();
                ref.read(authProvider.notifier).logout();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
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
}