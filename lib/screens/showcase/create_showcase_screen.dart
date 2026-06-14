import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CreateShowcaseScreen extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> jobData;

  const CreateShowcaseScreen({
    super.key,
    required this.requestId,
    required this.jobData,
  });

  @override
  State<CreateShowcaseScreen> createState() =>
      _CreateShowcaseScreenState();
}

class _CreateShowcaseScreenState
    extends State<CreateShowcaseScreen> {

  static const cloudName = 'dcresvgii';
  static const uploadPreset = 'unsigned_preset';

  final ImagePicker picker = ImagePicker();

  final TextEditingController captionController =
  TextEditingController();

  bool isLoading = false;

  List<String> beforeImages = [];
  List<String> afterImages = [];

  Future<String?> uploadToCloudinary(
      XFile file,
      ) async {

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final bytes = await file.readAsBytes();

    final request =
    http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
        ),
      );

    final response = await request.send();

    final body =
    await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(body);
      return data['secure_url'];
    }

    return null;
  }

  Future<void> pickBeforeImages() async {
    final images =
    await picker.pickMultiImage();

    if (images.isEmpty) return;

    setState(() => isLoading = true);

    for (final image in images) {
      final url =
      await uploadToCloudinary(image);

      if (url != null) {
        beforeImages.add(url);
      }
    }

    setState(() => isLoading = false);
  }

  Future<void> pickAfterImages() async {
    final images =
    await picker.pickMultiImage();

    if (images.isEmpty) return;

    setState(() => isLoading = true);

    for (final image in images) {
      final url =
      await uploadToCloudinary(image);

      if (url != null) {
        afterImages.add(url);
      }
    }

    setState(() => isLoading = false);
  }

  Future<void> submitShowcase() async {

    if (beforeImages.isEmpty ||
        afterImages.isEmpty) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Upload before and after images",
          ),
        ),
      );

      return;
    }

    setState(() => isLoading = true);

    try {

      final uid =
          FirebaseAuth.instance.currentUser!.uid;

      final techDoc =
      await FirebaseFirestore.instance
          .collection('technicians')
          .doc(uid)
          .get();

      final tech =
          techDoc.data() ?? {};

      await FirebaseFirestore.instance
          .collection('showcases')
          .add({

        "requestId": widget.requestId,

        "technicianId": uid,

        "technicianName":
        tech['name'] ?? "",

        "technicianPhoto":
        tech['profilePic'] ?? "",

        "service":
        widget.jobData['service'] ?? "",

        "location":
        widget.jobData[
        'serviceLocationAddress'] ??
            "",

        "caption":
        captionController.text.trim(),

        "beforeImages":
        beforeImages,

        "afterImages":
        afterImages,

        "createdAt":
        Timestamp.now(),
      });

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Showcase posted successfully",
          ),
        ),
      );

    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );

    }

    setState(() => isLoading = false);
  }

  Widget imagePreview(
      List<String> images,
      ) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (_, index) {

          return Padding(
            padding:
            const EdgeInsets.only(
              right: 8,
            ),
            child: ClipRRect(
              borderRadius:
              BorderRadius.circular(10),
              child: Image.network(
                images[index],
                width: 90,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title:
        const Text("Create Showcase"),
      ),
      body: SingleChildScrollView(
        padding:
        const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [

            Text(
              widget.jobData['service'] ??
                  "Service",
              style:
              const TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Before Images",
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed:
              pickBeforeImages,
              child: const Text(
                "Upload Before Images",
              ),
            ),

            if (beforeImages.isNotEmpty)
              imagePreview(
                beforeImages,
              ),

            const SizedBox(height: 20),

            const Text(
              "After Images",
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed:
              pickAfterImages,
              child: const Text(
                "Upload After Images",
              ),
            ),

            if (afterImages.isNotEmpty)
              imagePreview(
                afterImages,
              ),

            const SizedBox(height: 20),

            TextField(
              controller:
              captionController,
              maxLines: 4,
              decoration:
              const InputDecoration(
                labelText:
                "Describe the work",
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child:
              ElevatedButton(
                onPressed:
                isLoading
                    ? null
                    : submitShowcase,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                  "Post Showcase",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}