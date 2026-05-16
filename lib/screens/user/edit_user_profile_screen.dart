import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class EditUserProfileScreen extends StatefulWidget {
  const EditUserProfileScreen({super.key});

  @override
  State<EditUserProfileScreen> createState() => _EditUserProfileScreenState();
}

class _EditUserProfileScreenState extends State<EditUserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController =
  TextEditingController();

  final TextEditingController locationController =
  TextEditingController();

  final TextEditingController phoneController =
  TextEditingController();

  final ImagePicker _picker = ImagePicker();


  double? userLat;
  double? userLng;

  String profileImageUrl = '';
  File? localImageFile;
  bool isSaving = false;
  bool isUploadingImage = false;
  bool isLoading = true;


  ImageProvider? getProfileImage() {
    if (localImageFile != null) {
      return FileImage(localImageFile!);
    }

    if (profileImageUrl.isNotEmpty) {
      return NetworkImage(profileImageUrl);
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();

    setState(() {
      nameController.text = data?['name'] ?? '';
      locationController.text = data?['location'] ?? '';
      profileImageUrl = data?['profilePic'] ?? '';

      phoneController.text = user.phoneNumber ?? 'No phone number';

      isLoading = false;
    });
  }




  Future<String?> uploadToCloudinary(File imageFile) async {
    const cloudName = "dcresvgii";
    const uploadPreset = "unsigned_preset";

    final url =
    Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    try {
      final request = http.MultipartRequest("POST", url);

      request.fields['upload_preset'] = uploadPreset;
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      debugPrint("Cloudinary response: $resBody");

      final decoded = json.decode(resBody);

      if (decoded['secure_url'] != null) {
        return decoded['secure_url'];
      } else {
        throw Exception("Invalid response: $resBody");
      }
    } catch (e) {
      debugPrint("Cloudinary error: $e");
      return null;
    }
  }


  Future<void> _pickImage() async {
    final pickedFile =
    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

    if (pickedFile == null) return;

    setState(() {
      localImageFile = File(pickedFile.path); // instant UI update
    });
  }


  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String imageUrlToSave = profileImageUrl;

      // upload new image if selected
      if (localImageFile != null) {
        final uploadedUrl = await uploadToCloudinary(localImageFile!);

        if (uploadedUrl != null) {
          imageUrlToSave = uploadedUrl;
          profileImageUrl = uploadedUrl; // update UI too
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        "name": nameController.text.trim(),
        "location": locationController.text.trim(),
        "phone": phoneController.text.trim(),
        "profilePic": imageUrlToSave,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated")),
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("SAVE ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Update failed")),
      );
    }

    setState(() => isSaving = false);
  }

  // ---------------- PHONE FIELD ----------------
  Widget _field({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      validator: (value) {
        if (!readOnly && (value == null || value.isEmpty)) {
          return "Required";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit user profile"),),
      body: isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 10),
                CircleAvatar(
                  key: ValueKey(localImageFile?.path ?? profileImageUrl),
                  radius: 50,
                  backgroundImage: localImageFile != null
                      ? FileImage(localImageFile!)
                      : profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: (localImageFile == null && profileImageUrl.isEmpty)
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),



                const SizedBox(height: 20),

                _field(
                  controller: phoneController,
                  label: "Phone Number",
                  readOnly: true,
                ),

                const SizedBox(height: 15),



                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value!.isEmpty ? "Enter Full Name" : null,
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: "Address",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value!.isEmpty ? "Enter address" : null,
                ),



                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.image, color: Colors.grey),
                        SizedBox(width: 10),
                        Text("Change Profile Picture"),
                        Spacer(),
                        Icon(Icons.upload),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 15,),

                ElevatedButton(
                  onPressed: isSaving ? null : _saveProfile,
                  child: const Text("Save Changes"),
                ),
              ],
            )),

      ),
      );

  }
}
