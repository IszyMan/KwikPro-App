import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_checkbox_tile.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_page_container.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/onboarding_header.dart';
import 'privacy_policy.dart';
import 'terms_and_conditions.dart';
import 'user_main_screen.dart';

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class UserSignupScreen extends ConsumerStatefulWidget {
  const UserSignupScreen({super.key});

  @override
  ConsumerState<UserSignupScreen> createState() =>
      _UserSignupScreenState();
}

class _UserSignupScreenState
    extends ConsumerState<UserSignupScreen> {
  final nameController = TextEditingController();
  final addressController = TextEditingController();

  bool acceptedLegal = false;
  bool isLoading = false;

  File? selectedImage;
  String? uploadedImageUrl;
  static const cloudName = 'dcresvgii';
  static const uploadPreset = 'unsigned_preset';
  final ImagePicker picker = ImagePicker();

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    super.dispose();
  }


  Future<String?> uploadToCloudinary(XFile file) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final bytes = await file.readAsBytes();

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
        ),
      );

    final response = await request.send();

    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final json = jsonDecode(body);

      return json['secure_url'];
    }

    debugPrint(body);

    return null;
  }


  Future<void> pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take Photo"),
              onTap: () => Navigator.pop(
                context,
                ImageSource.camera,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Choose from Gallery"),
              onTap: () => Navigator.pop(
                context,
                ImageSource.gallery,
              ),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(source: source);

    if (picked == null) return;

    setState(() {
      selectedImage = File(picked.path);
    });

    final url = await uploadToCloudinary(picked);

    if (url != null) {
      uploadedImageUrl = url;
    }
  }

  Future<void> _saveUser() async {
    if (!acceptedLegal) return;

    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your full name."),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    final auth = ref.read(authProvider);
    final uid = auth.user!.uid;

    Position? pos;

    try {
      bool serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (serviceEnabled) {
        LocationPermission permission =
        await Geolocator.checkPermission();

        if (permission == LocationPermission.denied) {
          permission =
          await Geolocator.requestPermission();
        }

        if (permission != LocationPermission.denied &&
            permission !=
                LocationPermission.deniedForever) {
          pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );
        }
      }
    } catch (_) {}

    String address =
    addressController.text.trim().isNotEmpty
        ? addressController.text.trim()
        : "Unknown";

    if (pos != null) {
      try {
        final placemarks =
        await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );

        final place = placemarks.first;

        address = place.subLocality ??
            place.locality ??
            "Unknown";
      } catch (_) {}
    }

    final userData = {
      'uid': uid,
      'name': nameController.text.trim(),
      'phoneNumber': auth.user!.phoneNumber,
      'profilePic': uploadedImageUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'currentAddress': address,
      'lat': pos?.latitude,
      'lng': pos?.longitude,
      'role': 'user',
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set(userData);

    if (!mounted) return;

    setState(() => isLoading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const UserMainScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPageContainer(
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            const Center(
              child: AppLogo(size: 90),
            ),

            const SizedBox(height: 18),

            const Center(
              child: OnboardingHeader(
                title: Text("Complete Your Profile"),
                subtitle:
                "Tell us a little about yourself so technicians can easily identify and assist you.",
              ),
            ),




            const SizedBox(height: 15),

            AppTextField(
              controller: nameController,
              label: "Full Name",
              hint: "John Doe",
              icon: Icons.person_outline,
            ),

            const SizedBox(height: 15),

            AppTextField(
              controller: addressController,
              label: "Neighborhood / Area",
              hint: "e.g. Wuse 2",
              icon: Icons.location_on_outlined,
            ),

            const SizedBox(height: 15),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Profile Photo (Optional)",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),

                const SizedBox(height: 8),

                InkWell(
                  onTap: pickImage,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 62,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.lightBlue,
                          backgroundImage: selectedImage != null
                              ? FileImage(selectedImage!)
                              : uploadedImageUrl != null
                              ? NetworkImage(uploadedImageUrl!)
                              : null,
                          child: selectedImage == null &&
                              uploadedImageUrl == null
                              ? const Icon(
                            Icons.person,
                            size: 20,
                            color: AppColors.primary,
                          )
                              : null,
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Text(
                            uploadedImageUrl == null
                                ? "Upload Profile Photo"
                                : "Profile Photo Selected",
                            style: TextStyle(
                              fontSize: 15,
                              color: uploadedImageUrl == null
                                  ? Colors.grey.shade700
                                  : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        Text(
                          uploadedImageUrl == null
                              ? "Upload"
                              : "Change",
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(width: 4),

                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),



            const SizedBox(height: 15),

            AppCheckboxTile(
              value: acceptedLegal,
              onChanged: (value) {
                setState(() {
                  acceptedLegal = value ?? false;
                });
              },
              onPrivacyTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const PrivacyPolicy(),
                  ),
                );
              },
              onTermsTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const TermsAndConditions(),
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text(
                "We respect your privacy. Your information is only used to connect you with nearby technicians.",
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                  height: 1.5,
                ),
              ),
            ),

            const Spacer(),

            AppPrimaryButton(
              text: "Continue",
              loading: isLoading,
              onPressed:
              acceptedLegal ? _saveUser : null,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}