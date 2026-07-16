import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../providers/technician_signup_controller.dart';
import '../../../widgets/app_primary_button.dart';
import '../../../widgets/onboarding_header.dart';
import '../../../widgets/upload_image_card.dart';

class Step1ProfileImage extends ConsumerWidget {
  const Step1ProfileImage({super.key});

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
        return jsonDecode(body)['secure_url'];
      }

      debugPrint(body);
      return null;
    }

    Future<void> pickAndUpload() async {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (_) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text("Take Selfie"),
                onTap: () =>
                    Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text("Choose from Gallery"),
                onTap: () =>
                    Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final picked = await picker.pickImage(source: source);

      if (picked == null) return;

      ref
          .read(technicianSignupController.notifier)
          .addImage(
        type: 'profile',
        path: picked.path,
      );

      final url = await uploadToCloudinary(picked);

      if (url != null) {
        ref
            .read(technicianSignupController.notifier)
            .addImage(
          type: 'profile',
          path: url,
        );
      }
    }

    final hasImage =
        state.profileImage != null &&
            state.profileImage!.isNotEmpty;

    ImageProvider? imageProvider;

    if (hasImage) {
      imageProvider = state.profileImage!.startsWith('http')
          ? NetworkImage(state.profileImage!)
          : FileImage(File(state.profileImage!));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const OnboardingHeader(
            title: Text("Add Your Profile Photo"),
            subtitle:
            "A clear profile photo helps customers recognize and trust you.",
          ),

          const SizedBox(height: 30),

          UploadImageCard(
            title: hasImage
                ? "Change Profile Photo"
                : "Upload Profile Photo",
            subtitle:
            "Take a selfie or choose one from your gallery",
            onTap: pickAndUpload,
          ),

          if (hasImage) ...[
            const SizedBox(height: 30),

            Stack(
              alignment: Alignment.topRight,
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundImage: imageProvider,
                ),

                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    ref
                        .read(
                      technicianSignupController.notifier,
                    )
                        .addImage(
                      type: 'profile',
                      path: '',
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 40),

          AppPrimaryButton(
            text: "Continue",
            onPressed: hasImage
                ? () {
              ref
                  .read(
                technicianSignupController.notifier,
              )
                  .nextStep();
            }
                : null,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}