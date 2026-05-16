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
  final TextEditingController phoneController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  String profileImageUrl = '';
  XFile? localProfileImage;

  String selectedService = '';
  List<String> selectedSkills = [];


  List<String> workImages = [];

  bool isSaving = false;

  final List<String> services = [
    "AC Repairer",
    "Plumber",
    "Generator Repairer",
    "Electrician",
    "Painter",
    "Fridge Repairer",
  ];

  static Map<String, List<String>> serviceSkills = {
    "Car Mechanic": [
      "Battery Services",
      "Car Rewire",
      "AC Repair",
      "Brake Service",
      "German Car",
      "American Car",
      "Japanese Car",

    ],

    "Electrician": [
      "Wiring",
      "Socket Fixing",
      "Lighting Installation",
    ],
    "AC Repairer": [
      "AC Gas Filling",
      "AC Repair",
      "AC Installation",
      "Compressor Repair",
    ],
    "Plumber": [
      "Leak Fixing",
      "Drain Cleaning",
      "Toilet Repair",
      "Water Treatment",
      "Pumping Machine",
    ],
    "Generator Repairer": [
      "Generator Servicing",
      "Engine Repair",
      "Oil Change",
      "Carburetor",
    ],
    "Fridge Repairer": [
      "Freezer Repair"
          "Gas Filling",
      "Refrigerator Repair",

    ],
    "Painter": [
      "Interior Painting",
      "Exterior Painting",
      "Wall Screeding",
      "Wallpaper installation",
    ]
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ---------------- LOAD DATA ----------------
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
      selectedSkills = List<String>.from(data['skills'] ?? []);

      /// FIX: safe fallback + correct field
      workImages = List<String>.from(data['previousWorkImages'] ?? []);

      phoneController.text =
          FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    });
  }

  // ---------------- CLOUDINARY UPLOAD ----------------
  Future<String?> uploadToCloudinary(XFile file) async {
    const cloudName = "dcresvgii";
    const uploadPreset = "unsigned_preset";

    final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final bytes = await file.readAsBytes();

    final request = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
        ),
      );

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    final data = json.decode(resBody);

    if (response.statusCode == 200) {
      return data['secure_url'];
    } else {
      debugPrint("Upload failed: $resBody");
      return null;
    }
  }

  // ---------------- PROFILE IMAGE ----------------
  Future<void> _pickProfileImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      localProfileImage = picked;
    });
  }

  // ---------------- ADD WORK IMAGE ----------------
  Future<void> _addWorkImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final url = await uploadToCloudinary(picked);
    if (url == null) return;

    setState(() {
      workImages.add(url);
    });
  }

  // ---------------- REMOVE IMAGE ----------------
  void _removeWorkImage(String url) {
    setState(() {
      workImages = List.from(workImages)..remove(url);
    });
  }

  // ---------------- SAVE ----------------
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String imageUrl = profileImageUrl;

      if (localProfileImage != null) {
        final uploaded =
        await uploadToCloudinary(localProfileImage!);

        if (uploaded != null) {
          imageUrl = uploaded;
        }
      }

      await FirebaseFirestore.instance
          .collection('technicians')
          .doc(user.uid)
          .update({
        "location": _locationController.text.trim(),
        "service": selectedService,
        "skills": selectedSkills,
        "profilePic": imageUrl,

        /// 🔥 SAFE WRITE
        "previousWorkImages":
        workImages.where((e) => e.isNotEmpty).toList(),

        "updatedAt": FieldValue.serverTimestamp(),
      });

      setState(() {
        profileImageUrl = imageUrl;
        localProfileImage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("SAVE ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Update failed")),
      );
    }

    setState(() => isSaving = false);
  }

  // ---------------- WORK GALLERY ----------------
  Widget _buildWorkGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Previous Work Images",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: workImages.length + 1,
            itemBuilder: (context, index) {
              if (index == workImages.length) {
                return GestureDetector(
                  onTap: _addWorkImage,
                  child: Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo),
                        SizedBox(height: 8),
                        Text("Add Image"),
                      ],
                    ),
                  ),
                );
              }

              final url = workImages[index];

              return Stack(
                children: [
                  Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(url),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  Positioned(
                    top: 6,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => _removeWorkImage(url),
                      child: const CircleAvatar(
                        radius: 12,
                        child: Icon(Icons.close, size: 14),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final skills = serviceSkills[selectedService] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickProfileImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: localProfileImage != null
                      ? FileImage(File(localProfileImage!.path))
                      : profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: const Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: phoneController,
                readOnly: true,
                decoration: const InputDecoration(labelText: "Phone"),
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: _locationController,
                decoration:
                const InputDecoration(labelText: "Location"),
              ),

              const SizedBox(height: 15),

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
                    selectedService = val!;
                    selectedSkills = [];
                  });
                },
                decoration:
                const InputDecoration(labelText: "Service Type"),
              ),

              const SizedBox(height: 10),

              ...skills.map((skill) => CheckboxListTile(
                value: selectedSkills.contains(skill),
                title: Text(skill),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      selectedSkills.add(skill);
                    } else {
                      selectedSkills.remove(skill);
                    }
                  });
                },
              )),

              const SizedBox(height: 20),

              _buildWorkGallery(),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text("Save Changes"),
              )
            ],
          ),
        ),
      ),
    );
  }
}