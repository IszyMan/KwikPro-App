import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../../providers/technician_signup_controller.dart';
import '../../../widgets/app_primary_button.dart';
import '../../../widgets/onboarding_header.dart';
import '../../../widgets/upload_image_card.dart';
import '../../user/privacy_policy.dart';
import '../../user/terms_and_conditions.dart';

class Step4Verification extends ConsumerStatefulWidget {
  const Step4Verification({super.key});

  @override
  ConsumerState<Step4Verification> createState() =>
      _Step4VerificationState();
}

class _Step4VerificationState
    extends ConsumerState<Step4Verification> {
  static const cloudName = "dcresvgii";
  static const uploadPreset = "unsigned_preset";

  bool acceptedLegal = false;

  Future<String?> uploadToCloudinary(XFile file) async {
    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final bytes = await file.readAsBytes();

    final request = http.MultipartRequest("POST", uri)
      ..fields["upload_preset"] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          "file",
          bytes,
          filename: file.name,
        ),
      );

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(body)["secure_url"];
    }

    debugPrint(body);
    return null;
  }

  Future<void> pickAndUploadNin() async {
    final picker = ImagePicker();

    final picked =
    await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    final notifier =
    ref.read(technicianSignupController.notifier);

    notifier.addImage(
      type: "nin",
      path: picked.path,
    );

    final url = await uploadToCloudinary(picked);

    if (url != null) {
      notifier.addImage(
        type: "nin",
        path: url,
      );
    }
  }

  ImageProvider getImage(String path) {
    if (path.startsWith("http")) {
      return NetworkImage(path);
    }

    return FileImage(File(path));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(technicianSignupController);

    final notifier =
    ref.read(technicianSignupController.notifier);

    final ninImage = state.ninImage;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const OnboardingHeader(
            title: Text("Final Verification"),
            subtitle:
            "Upload a valid government ID to verify your identity. This helps customers trust your profile.",
          ),

          const SizedBox(height: 28),

          UploadImageCard(
            title: "Government ID / NIN",
            subtitle: "Upload your NIN Slip or valid ID",
            onTap: pickAndUploadNin,
          ),

          if (ninImage != null && ninImage.isNotEmpty) ...[

            const SizedBox(height: 18),

            Stack(
              children: [

                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image(
                    image: getImage(ninImage),
                    height: 140,
                    width: 140,
                    fit: BoxFit.cover,
                  ),
                ),

                Positioned(
                  top: 12,
                  right: 12,
                  child: InkWell(
                    onTap: () {
                      notifier.addImage(
                        type: "nin",
                        path: "",
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
                ),
              ],
            ),
          ],

          const SizedBox(height: 30),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [

                Checkbox(
                  value: acceptedLegal,
                  onChanged: (v) {
                    setState(() {
                      acceptedLegal = v ?? false;
                    });
                  },
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [

                      Wrap(
                        children: [

                          const Text(
                            "I agree to KwikPro's ",
                          ),

                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                  const PrivacyPolicy(),
                                ),
                              );
                            },
                            child: const Text(
                              "Privacy Policy",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ),

                          const Text(" and "),

                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                  const TermsAndConditions(),
                                ),
                              );
                            },
                            child: const Text(
                              "Terms & Conditions",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Your documents are encrypted and used only for verification. They are never displayed publicly.",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          AppPrimaryButton(
            text: "Finish Registration",
            loading: state.isLoading,
            onPressed: acceptedLegal &&
                ninImage != null &&
                ninImage.isNotEmpty
                ? () {
              notifier.submit(context, ref);
            }
                : null,
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}