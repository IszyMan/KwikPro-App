import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../providers/technician_signup_controller.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_primary_button.dart';
import '../../../widgets/onboarding_header.dart';
import '../../../widgets/upload_image_card.dart';

class Step3Uploads extends ConsumerWidget {
  const Step3Uploads({super.key});

  static const cloudName = 'dcresvgii';
  static const uploadPreset = 'unsigned_preset';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picker = ImagePicker();
    final state = ref.watch(technicianSignupController);

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
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(body);
        return data['secure_url'];
      }

      debugPrint(body);
      return null;
    }

    Future<void> pickAndUpload(String type) async {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile == null) return;

      final localPath = pickedFile.path;

      ref
          .read(technicianSignupController.notifier)
          .addImage(
        type: type,
        path: localPath,
      );

      final url = await uploadToCloudinary(pickedFile);

      if (url != null) {
        ref
            .read(technicianSignupController.notifier)
            .removeImage(
          type: type,
          path: localPath,
        );

        ref
            .read(technicianSignupController.notifier)
            .addImage(
          type: type,
          path: url,
        );
      }
    }

    ImageProvider getImage(String path) {
      return path.startsWith("http")
          ? NetworkImage(path)
          : FileImage(File(path));
    }

    Widget imageGallery({
      required List<String> images,
      required String type,
    }) {
      return SizedBox(
        height: 95,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: images.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final path = images[index];

            return Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.border,
                    ),
                    image: DecorationImage(
                      image: getImage(path),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      ref
                          .read(
                        technicianSignupController.notifier,
                      )
                          .removeImage(
                        type: type,
                        path: path,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingHeader(
            title: Text("Show Your Work"),
            subtitle:
            "Upload photos of your working tools and previous jobs to help customers trust your workmanship.",
          ),

          const SizedBox(height: 30),

          UploadImageCard(
            title: "Working Tools",
            subtitle: "Upload photos of your tools",
            onTap: () => pickAndUpload("tools"),
          ),

          if (state.toolsImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            imageGallery(
              images: state.toolsImages,
              type: "tools",
            ),
          ],

          const SizedBox(height: 28),

          UploadImageCard(
            title: "Previous Jobs",
            subtitle: "Upload photos of completed jobs",
            onTap: () => pickAndUpload("work"),
          ),

          if (state.workImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            imageGallery(
              images: state.workImages,
              type: "work",
            ),
          ],

          const SizedBox(height: 40),

          AppPrimaryButton(
            text: "Continue",
            onPressed: () {
              ref
                  .read(technicianSignupController.notifier)
                  .nextStep();
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}