import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kwikpro/providers/auth_provider.dart';
import 'package:kwikpro/screens/user/user_main_screen.dart';

class UserSignupScreen extends ConsumerStatefulWidget {
  const UserSignupScreen({super.key});

  @override
  ConsumerState<UserSignupScreen> createState() => _UserSignupScreenState();
}

class _UserSignupScreenState extends ConsumerState<UserSignupScreen> {
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final imageController = TextEditingController();

  Future<void> _saveUser() async {
    final auth = ref.read(authProvider);
    final uid = auth.user!.uid;


    Position? pos;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();

        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );
        }
      }
    } catch (e) {
      pos = null;
    }

    String address = addressController.text.trim().isNotEmpty
        ? addressController.text.trim()
        : "Unknown";

    if (pos != null) {
      try {
        final placemarks =
        await placemarkFromCoordinates(pos.latitude, pos.longitude);

        final place = placemarks.first;

        address = place.subLocality ?? place.locality ?? "Unknown";
      } catch (e) {}
    }

    final userData = {
      'uid': uid,
      'name': nameController.text.trim(),
      'profilePic': imageController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),

      'currentAddress': address,
      'lat': pos?.latitude,
      'lng': pos?.longitude,
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set(userData);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const UserMainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Welcome! Please Complete Your KwikPro Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Full Name")),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: "Your Area")),
            TextField(controller: imageController, decoration: const InputDecoration(labelText: "Image url (optional)")),
            const Spacer(),
            ElevatedButton(onPressed: _saveUser, child: const Text("Continue")),
          ],
        ),
      ),
    );
  }
}