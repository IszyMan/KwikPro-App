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
      await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile == null) return;

      final localPath = pickedFile.path;

      /// LOCAL PREVIEW
      ref
          .read(technicianSignupController.notifier)
          .addImage(
        type: type,
        path: localPath,
      );

      /// UPLOAD
      final url =
      await uploadToCloudinary(pickedFile);

      if (url != null) {

        /// REMOVE LOCAL
        ref
            .read(
            technicianSignupController.notifier)
            .removeImage(
          type: type,
          path: localPath,
        );

        /// ADD CLOUD
        ref
            .read(
            technicianSignupController.notifier)
            .addImage(
          type: type,
          path: url,
        );
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
    Widget imageGallery({
      required String label,
      required String type,
      required List<String> images,
    }) {

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length + 1,
              itemBuilder: (context, index) {

                /// ADD BUTTON
                if (index == images.length) {
                  return GestureDetector(
                    onTap: () => pickAndUpload(type),
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey),
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

                final path = images[index];

                return Stack(
                  children: [

                    Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: getImage(path)!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    Positioned(
                      top: 6,
                      right: 16,
                      child: GestureDetector(
                        onTap: () {

                          ref
                              .read(
                              technicianSignupController.notifier)
                              .removeImage(
                            type: type,
                            path: path,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                    )
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 24),
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
        title: const Text("Upload image of working tools & previous jobs"),
      ),
      body: Padding(padding: EdgeInsetsGeometry.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ///  TOOLS IMAGE
              imageGallery(
                label: "Your Working Tools 🔧",
                type: "tools",
                images: state.toolsImages,
              ),

              imageGallery(
                label: "Images of Previous Work",
                type: "work",
                images: state.workImages,
              ),

              SizedBox(height: 10),

              ElevatedButton(
                onPressed: () =>
                    ref.read(technicianSignupController.notifier).nextStep(),
                child: Text("Next"),
              ),
            ],
          ),
        )
      ),
    );

  }
}