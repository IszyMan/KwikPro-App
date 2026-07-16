import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppUploadField extends StatelessWidget {
  final String label;
  final String? imagePath;
  final VoidCallback onUpload;
  final VoidCallback? onRemove;

  const AppUploadField({
    super.key,
    required this.label,
    required this.imagePath,
    required this.onUpload,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        imagePath != null &&
            imagePath!.isNotEmpty;

    ImageProvider? provider;

    if (hasImage) {
      provider = imagePath!.startsWith("http")
          ? NetworkImage(imagePath!)
          : FileImage(File(imagePath!));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 10),

        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onUpload,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Row(
              children: [

                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                  AppColors.lightBlue,
                  backgroundImage: provider,
                  child: !hasImage
                      ? const Icon(
                    Icons.camera_alt,
                    color:
                    AppColors.primary,
                  )
                      : null,
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Text(
                    hasImage
                        ? "Tap to change photo"
                        : "Upload a photo",
                  ),
                ),

                if (hasImage && onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(
                      Icons.close,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}