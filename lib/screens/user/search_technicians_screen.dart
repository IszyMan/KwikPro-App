import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'technician_search_result_screen.dart';

class SearchTechnicianScreen extends StatefulWidget {
  const SearchTechnicianScreen({super.key});

  @override
  State<SearchTechnicianScreen> createState() =>
      _SearchTechnicianScreenState();
}

class _SearchTechnicianScreenState extends State<SearchTechnicianScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedService;
  String _location = "";
  String _issue = "";

  final TextEditingController _issueController = TextEditingController();

  bool _loading = false;

  XFile? _image;
  String _imageUrl = "";

  final ImagePicker _picker = ImagePicker();

  double? userLat;
  double? userLng;

  final List<String> services = [
    "Car Mechanic",
    "AC Repairer",
    "Plumber",
    "Generator Repairer",
    "Electrician",
    "Painter",
    "Fridge Repairer",
  ];

  List<String> _selectedSkills = [];

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
    "Electrician": ["Wiring", "Socket Fixing", "Lighting Installation"],
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
      "Freezer Repair",
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

  static const cloudName = 'dcresvgii';
  static const uploadPreset = 'unsigned_preset';

  Future<String?> uploadToCloudinary(XFile file) async {
    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final bytes = await file.readAsBytes();

    final request = http.MultipartRequest("POST", uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(http.MultipartFile.fromBytes(
        "file",
        bytes,
        filename: file.name,
      ));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(body)['secure_url'];
    }
    return null;
  }

  Future<void> pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Camera"),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text("Gallery"),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    setState(() => _image = picked);

    final url = await uploadToCloudinary(picked);
    if (url != null) {
      setState(() => _imageUrl = url);
    }
  }

  Future<void> _searchTechnicians() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a service")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final pos = await Geolocator.getCurrentPosition();

      userLat = pos.latitude;
      userLng = pos.longitude;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TechnicianSearchResultsScreen(
            service: _selectedService,
            userLat: userLat,
            userLng: userLng,
            serviceLocationAddress: _location,
            issueDescription: _issue,
            imageUrl: _imageUrl,
            selectedSkills: _selectedSkills,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location error")),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text("Find Technician")),

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              /// HEADER
              _card(
                color: Colors.blue,
                child: const Text(
                  "Tell us what you need — we’ll match the best technician near you",
                  style: TextStyle(color: Colors.white),
                ),
              ),

              const SizedBox(height: 12),

              /// LOCATION
              _inputCard(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Enter Service Location",
                    prefixIcon: Icon(Icons.location_on),
                    border: InputBorder.none,
                  ),
                  onChanged: (v) => _location = v,
                  validator: (v) =>
                  v == null || v.isEmpty ? "Enter location" : null,
                ),
              ),

              /// SERVICE
              _inputCard(
                child: DropdownButtonFormField(
                  value: _selectedService,
                  decoration: const InputDecoration(
                    labelText: "Select Service",
                    border: InputBorder.none,
                  ),
                  items: services
                      .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedService = v;
                      _selectedSkills.clear();
                    });
                  },
                ),
              ),

              /// SKILLS (UNCHANGED)
              if (_selectedService != null &&
                  serviceSkills.containsKey(_selectedService))
                _inputCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Service Description",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ...serviceSkills[_selectedService!]!.map((skill) {
                        final selected = _selectedSkills.contains(skill);

                        return CheckboxListTile(
                          value: selected,
                          title: Text(skill),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedSkills.add(skill);
                              } else {
                                _selectedSkills.remove(skill);
                              }

                              _issueController.text =
                                  _selectedSkills.join(', ');
                              _issue = _issueController.text;
                            });
                          },
                        );
                      })
                    ],
                  ),
                ),
              _inputCard(
                child: TextFormField(
                  controller: _issueController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: "Describe your issue",
                    border: InputBorder.none,
                  ),
                  onChanged: (v) => _issue = v,
                ),
              ),


              _inputCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Upload Job Image (Optional)"),
                          const SizedBox(height: 6),
                          ElevatedButton.icon(
                            onPressed: pickImage,
                            icon: const Icon(Icons.upload),
                            label: const Text("Upload"),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    if (_image != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 70,
                          width: 70,
                          child: kIsWeb
                              ? Image.network(_image!.path, fit: BoxFit.cover)
                              : Image.file(File(_image!.path),
                              fit: BoxFit.cover),
                        ),
                      )
                    else
                      Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.image),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _loading ? null : _searchTechnicians,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                "SEARCH TECHNICIANS",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );

  }

  Widget _card({required Widget child, Color? color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _inputCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }
}