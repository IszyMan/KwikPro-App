import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class EditTechnicianProfileScreen extends StatefulWidget {
  const EditTechnicianProfileScreen({super.key});

  @override
  State<EditTechnicianProfileScreen> createState() =>
      _EditTechnicianProfileScreenState();
}

class _EditTechnicianProfileScreenState
    extends State<EditTechnicianProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  String profileImageUrl = '';
  File? localImageFile;
  String selectedService = '';
  bool isSaving = false;
  bool isUploadingImage = false;

  ImageProvider? getProfileImage() {
    if (localImageFile != null) {
      return FileImage(localImageFile!);
    }

    if (profileImageUrl.isNotEmpty) {
      return NetworkImage(profileImageUrl);
    }

    return null;
  }

  final List<String> services = [
    "AC Repairer",
    "Plumber",
    "Generator Repairer",
    "Electrician",
    "Painter",
    "Fridge Repairer",
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }


  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('technicians')
        .doc(user.uid)
        .get();

    final data = doc.data();
    if (data == null) return;

    setState(() {
      _locationController.text = data['location'] ?? '';
      selectedService = data['service'] ?? '';
      profileImageUrl = data['profilePic'] ?? '';
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
      localImageFile = File(pickedFile.path); // ✅ instant UI update
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
          profileImageUrl = uploadedUrl; // ✅ update UI too
        }
      }

      await FirebaseFirestore.instance
          .collection('technicians')
          .doc(user.uid)
          .update({
        "location": _locationController.text.trim(),
        "service": selectedService,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),
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

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: "Area of Operation",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value!.isEmpty ? "Enter location" : null,
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: selectedService.isEmpty ? null : selectedService,
                items: services
                    .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s),
                ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedService = val ?? '';
                  });
                },
                decoration: const InputDecoration(
                  labelText: "Service Type",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.isEmpty
                    ? "Select a service"
                    : null,
              ),

              const SizedBox(height: 10),

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
          )
        ),
      ),
    );
  }
}