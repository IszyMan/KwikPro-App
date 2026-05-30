import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:kwikpro/screens/user/technician_search_result_screen.dart';
import 'dart:convert';
import 'dart:io';


import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class SearchTechnicianScreen extends StatefulWidget {
  const SearchTechnicianScreen({super.key});

  @override
  _SearchTechnicianScreenState createState() => _SearchTechnicianScreenState();
}

class _SearchTechnicianScreenState extends State<SearchTechnicianScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedService;
  String _serviceLocationAddress = '';

  final TextEditingController _issueController = TextEditingController();
  String _issueDescription = '';

  bool _loading = false;
  bool _isSearching = false;
  bool _hasSearched = false;

  String _imageUrl = '';
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  static const cloudName = 'dcresvgii';
  static const uploadPreset = 'unsigned_preset';

  double? userLat;
  double? userLng;

  Map<String, dynamic>? currentRequest;

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

    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      return data['secure_url'];
    } else {
      print(responseBody);
      return null;
    }
  }
  Future<void> pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text("Take Picture"),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: Icon(Icons.photo),
            title: Text("Choose From Gallery"),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (source == null) return;

    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile == null) return;

    setState(() {
      _selectedImage = pickedFile;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Uploading image...")),
    );

    final uploadedUrl = await uploadToCloudinary(pickedFile);

    if (uploadedUrl != null) {
      setState(() {
        _imageUrl = uploadedUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image uploaded")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Find Best Technicians Near You')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Form for search input
              Form(
                key: _formKey,
                child: Column(
                  children: [

                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Service Location (Where service is needed)',
                        hintText: 'e.g. 12 Allen Avenue, Ikeja',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => _serviceLocationAddress = val,
                      validator: (val) =>
                      val == null || val.isEmpty ? 'Enter service location' : null,
                    ),
                    SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Select Service',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedService,
                      items: services
                          .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedService = val;
                          _selectedSkills = [];
                        });
                      },
                      validator: (val) =>
                      val == null ? 'Please select a service' : null,
                    ),

                    SizedBox(height: 15),
                    if (_selectedService != null &&
                        serviceSkills.containsKey(_selectedService))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10),
          
                          Text(
                            "Service Description",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
          
                          ...serviceSkills[_selectedService!]!.map((skill) {
                            final isSelected = _selectedSkills.contains(skill);
          
                            return CheckboxListTile(
                              title: Text(skill),
                              value: isSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedSkills.add(skill);
                                  } else {
                                    _selectedSkills.remove(skill);
                                  }

                                  // Auto-fill description box
                                  _issueController.text = _selectedSkills.join(', ');

                                  // Update issue description variable too
                                  _issueDescription = _issueController.text;
                                });
                              },
                            );
                          }).toList(),
                        ],
                      ),

                    TextFormField(
                      controller: _issueController,
                      decoration: InputDecoration(
                        labelText: 'Describe your issue',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: (val) => _issueDescription = val,
                      validator: (val) {
                        if ((_selectedSkills.isEmpty) &&
                            (val == null || val.trim().isEmpty)) {
                          return 'Describe your issue';
                        }

                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Upload Job Image (Optional)",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 10),

                        if (_selectedImage != null)
                          Container(
                            height: 140,
                            width: double.infinity,
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb
                              ? Image.network(
                              _selectedImage!.path,
                                fit: BoxFit.cover,
                                )
                                    : Image.file(
                                File(_selectedImage!.path),
                                fit: BoxFit.cover,
                                ),
                              ),
                            ),


                        SizedBox(height: 10),

                        ElevatedButton.icon(
                          onPressed: pickImage,
                          icon: Icon(Icons.camera_alt),
                          label: Text("Take / Upload Picture"),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loading ? null : _searchTechnicians,
                      child: _loading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Search'),
                    ),
                  ],
                ),
              ),
          
          
          
          
          
            ],
          ),
        ),
      ),
    );
  }

  /// Search technicians and get user location
  Future<void> _searchTechnicians() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(accuracy: LocationAccuracy.high));

      setState(() {
        userLat = pos.latitude;
        userLng = pos.longitude;
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TechnicianSearchResultsScreen(
            service: _selectedService,
            userLat: userLat,
            userLng: userLng,
            serviceLocationAddress: _serviceLocationAddress,
            issueDescription: _issueDescription,
            imageUrl: _imageUrl,
            selectedSkills: _selectedSkills,
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to get location")));
    } finally {
      setState(() {
        _loading = false;
        _isSearching = false;
      });
    }
  }
}