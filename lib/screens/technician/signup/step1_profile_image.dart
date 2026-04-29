import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

import '../../../providers/technician_signup_controller.dart';

class Step1ProfileImage extends ConsumerWidget {
  const Step1ProfileImage({super.key});

  static const cloudName = 'dcresvgii';
  static const uploadPreset = 'unsigned_preset';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picker = ImagePicker();
    final state = ref.watch(technicianSignupController);

    Future<String?> uploadToCloudinary(XFile file) async {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final bytes = await file.readAsBytes();

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: file.name));

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(resBody);
        return data['secure_url'];
      } else {
        print('Cloudinary upload failed: $resBody');
        return null;
      }
    }

    Future pickAndUpload() async {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera),
              title: Text("Take Selfie"),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo),
              title: Text("Choose from Gallery"),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      );

      if (source == null) return;

      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null) return;

      // STEP 1: SHOW LOCAL PREVIEW IMMEDIATELY
      ref.read(technicianSignupController.notifier)
          .setImage(type: 'profile', path: pickedFile.path);

      // STEP 2: UPLOAD IN BACKGROUND
      final url = await uploadToCloudinary(pickedFile);

      // STEP 3: REPLACE WITH CLOUD URL
      if (url != null) {
        ref.read(technicianSignupController.notifier)
            .setImage(type: 'profile', path: url);
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final notifier =
            ref.read(technicianSignupController.notifier);

            if (state.step > 0) {
              notifier.back();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text("Upload Profile Image"),
      ),
      body: Padding(padding: EdgeInsetsGeometry.all(16),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: state.profileImage != null &&
                      state.profileImage!.isNotEmpty
                      ? (state.profileImage!.startsWith('http')
                      ? NetworkImage(state.profileImage!)
                      : FileImage(File(state.profileImage!)) as ImageProvider)
                      : null,
                  child: (state.profileImage == null ||
                      state.profileImage!.isEmpty)
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),

                ///  REMOVE BUTTON
                if (state.profileImage != null &&
                    state.profileImage!.isNotEmpty)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        ref
                            .read(technicianSignupController.notifier)
                            .setImage(type: 'profile', path: '');
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: pickAndUpload,
              child: Text(
                (state.profileImage == null ||
                    state.profileImage!.isEmpty)
                    ? "Upload / Take Selfie"
                    : "Change Image",
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: (state.profileImage != null &&
                  state.profileImage!.isNotEmpty)
                  ? () => ref
                  .read(technicianSignupController.notifier)
                  .nextStep()
                  : null,
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );

  }
}