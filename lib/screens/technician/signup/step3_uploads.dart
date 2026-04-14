import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import '../../../providers/technician_signup_controller.dart';

class Step3Uploads extends ConsumerWidget {
  const Step3Uploads({super.key});

  static const cloudName = 'dcresvgii';
  static const uploadPreset = 'unsigned_preset';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picker = ImagePicker();
    final state = ref.watch(technicianSignupController);

    ///  Upload to Cloudinary (Web + Mobile)
    Future<String?> uploadToCloudinary(XFile file) async {
      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudName/image/upload');

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
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(resBody);
        return data['secure_url'];
      } else {
        print('Upload failed: $resBody');
        return null;
      }
    }

    ///  Pick + preview + upload
    Future pickAndUpload(String type) async {
      final pickedFile =
      await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      ///  STEP 1: Instant preview (local)
      ref
          .read(technicianSignupController.notifier)
          .setImage(type: type, path: pickedFile.path);

      /// STEP 2: Upload in background
      final url = await uploadToCloudinary(pickedFile);

      /// STEP 3: Replace with cloud URL
      if (url != null) {
        ref
            .read(technicianSignupController.notifier)
            .setImage(type: type, path: url);
      }
    }

    /// Helper: show image correctly (local + network)
    ImageProvider? getImage(String? path) {
      if (path == null) return null;

      if (path.startsWith('http')) {
        return NetworkImage(path);
      } else {
        return FileImage(File(path));
      }
    }

    ///  UI CARD WITH REMOVE BUTTON
    Widget imageCard(String label, String type, String? path) {
      return Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(label,
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),

          Stack(
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                  image: path != null
                      ? DecorationImage(
                    image: getImage(path)!,
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: path == null
                    ? const Center(
                  child: Icon(Icons.image, size: 40, color: Colors.grey),
                )
                    : null,
              ),

              ///  REMOVE BUTTON
              if (path != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      ref
                          .read(technicianSignupController.notifier)
                          .setImage(type: type, path: '');
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: () => pickAndUpload(type),
            child: Text(path == null ? "Upload Image" : "Change Image"),
          ),

          const SizedBox(height: 20),
        ],
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          ///  TOOLS IMAGE
          imageCard(
            "Your Working Tools 🔧",
            "tools",
            state.toolsImage,
          ),

          /// WORK IMAGE
          imageCard(
            "Images of Your Previous Work",
            "work",
            state.workImage,
          ),

          SizedBox(height: 10),

          ElevatedButton(
            onPressed: () =>
                ref.read(technicianSignupController.notifier).nextStep(),
            child: Text("Next"),
          ),
        ],
      ),
    );
  }
}