import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../services/location_service.dart';

import 'technician_search_result_screen.dart';

class ServiceJobRequestScreen extends StatefulWidget {
  final String service;
  final String? initialLocation;
  final double? initialLat;
  final double? initialLng;

  const ServiceJobRequestScreen({
    super.key,
    required this.service,
    this.initialLocation,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<ServiceJobRequestScreen> createState() =>
      _ServiceJobRequestScreenState();
}

class _ServiceJobRequestScreenState extends State<ServiceJobRequestScreen> {
  final TextEditingController _issueController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  double? userLat;
  double? userLng;

  XFile? _image;
  Uint8List? _webImage;

  final ImagePicker picker = ImagePicker();

  bool loading = false;
  bool locating = false;

  bool _userEditedLocation = false;

  @override
  void initState() {
    super.initState();

    userLat = widget.initialLat;
    userLng = widget.initialLng;

    if (widget.initialLocation != null &&
        widget.initialLocation!.isNotEmpty) {
      _locationController.text = widget.initialLocation!;
    } else {
      _locationController.text = "Detecting location...";
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentLocation();
    });


  }

  Future<void> _loadCurrentLocation() async {
    try {
      setState(() {
        locating = true;
      });

      final result =
      await LocationService
          .getCurrentLocation();

      if (result == null) {
        setState(() {
          locating = false;
          _locationController.text =
          "Unable to get location";
        });
        return;
      }

      userLat =
      result["lat"];

      userLng =
      result["lng"];

      if (_userEditedLocation) {
        setState(() {
          locating = false;
        });
        return;
      }

      setState(() {
        locating = false;
        _locationController.text =
        result["address"];
      });
    } catch (e) {
      setState(() {
        locating = false;
        _locationController.text =
        "Unable to get location";
      });
    }
  }



  Future<void> _pickImage() async {
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

    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    if (kIsWeb) {
      _webImage = await picked.readAsBytes();
    }

    setState(() {
      _image = picked;
    });
  }

  /// =========================
  /// SEARCH TECHNICIANS
  /// =========================
  Future<void> _search() async {
    setState(() => loading = true);

    if (userLat == null || userLng == null) {
      final result =
      await LocationService
          .getCurrentLocation();

      if (result != null) {
        userLat = result["lat"];
        userLng = result["lng"];
      }
    }

    if (userLat == null || userLng == null) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to get location")),
      );
      return;
    }

    final address = _locationController.text.trim().isEmpty
        ? "Unknown location"
        : _locationController.text;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TechnicianSearchResultsScreen(
          service: widget.service,
          userLat: userLat!,
          userLng: userLng!,
          serviceLocationAddress: address,
          issueDescription: _issueController.text,
          imageUrl: _image?.path ?? "",
          selectedSkills: const [],
        ),
      ),
    );

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Request ${widget.service}"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Describe your issue",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            /// LOCATION
            _card(
              child: TextField(
                controller: _locationController,
                readOnly: false,
                onChanged: (v) => _userEditedLocation = true,
                decoration: InputDecoration(
                  prefixIcon: locating
                      ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.location_on),
                  hintText: "Enter Service location",
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// ISSUE
            _card(
              child: TextField(
                controller: _issueController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Describe your issue...",
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// IMAGE
            _card(
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text("Add Image"),
                  ),
                  const SizedBox(width: 10),

                  if (_image != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: kIsWeb
                          ? Image.memory(_webImage!,
                          width: 60, height: 60, fit: BoxFit.cover)
                          : Image.file(File(_image!.path),
                          width: 60, height: 60, fit: BoxFit.cover),
                    )
                  else
                    const Text("No image selected"),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : _search,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "SEARCH TECHNICIANS",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: child,
    );
  }
}