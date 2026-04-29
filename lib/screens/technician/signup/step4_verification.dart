import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import '../../../providers/technician_signup_controller.dart';

class Step4Verification extends ConsumerWidget {
  const Step4Verification({super.key});

  static const cloudName = 'dcresvgii';
  static const uploadPreset = 'unsigned_preset';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picker = ImagePicker();
    final state = ref.watch(technicianSignupController);

    ///  Upload (Web + Mobile)
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

    /// Pick + preview + upload
    Future pickAndUpload(String type) async {
      final pickedFile =
      await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      ///  STEP 1: instant preview
      ref
          .read(technicianSignupController.notifier)
          .setImage(type: type, path: pickedFile.path);

      /// STEP 2: upload
      final url = await uploadToCloudinary(pickedFile);

      ///  STEP 3: replace with cloud URL
      if (url != null) {
        ref
            .read(technicianSignupController.notifier)
            .setImage(type: type, path: url);
      }
    }

    /// Handle image (local + network)
    ImageProvider? getImage(String? path) {
      if (path == null || path.isEmpty) return null;

      if (path.startsWith('http')) {
        return NetworkImage(path);
      } else {
        return FileImage(File(path));
      }
    }

    ///  Image Card with remove button
    Widget imageCard() {
      final path = state.ninImage;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Upload NIN / ID",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  image: path != null && path.isNotEmpty
                      ? DecorationImage(
                    image: getImage(path)!,
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: path == null || path.isEmpty
                    ? const Center(
                  child:
                  Icon(Icons.badge, size: 40, color: Colors.grey),
                )
                    : null,
              ),

              /// REMOVE BUTTON
              if (path != null && path.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      ref
                          .read(technicianSignupController.notifier)
                          .setImage(type: 'nin', path: '');
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
            onPressed: () => pickAndUpload('nin'),
            child: Text(
              path == null || path.isEmpty
                  ? "Upload NIN / ID"
                  : "Change NIN / ID",
            ),
          ),
        ],
      );
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
        title: const Text("Upload image of your NIN"),
      ),
      body: Padding(padding: EdgeInsetsGeometry.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              imageCard(),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: (state.ninImage == null || state.ninImage!.isEmpty)
                    ? null
                    : () {
                  ref
                      .read(technicianSignupController.notifier)
                      .submit(context, ref);
                },
                child: state.isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Finish"),
              ),
            ],
          ),
        )
      ),
    );

  }
}