import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../../providers/technician_signup_controller.dart';
import '../../user/privacy_policy.dart';
import '../../user/terms_and_conditions.dart';

class Step4Verification extends ConsumerStatefulWidget {
  const Step4Verification({super.key});

  @override
  ConsumerState<Step4Verification> createState() =>
      _Step4VerificationState();
}

class _Step4VerificationState extends ConsumerState<Step4Verification> {
  static const cloudName = 'dcresvgii';
  static const uploadPreset = 'unsigned_preset';

  bool acceptedLegal = false;

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
    final resBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(resBody);
      return data['secure_url'];
    }

    debugPrint("Upload failed: $resBody");
    return null;
  }

  Future<void> pickAndUploadNin() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    final notifier = ref.read(technicianSignupController.notifier);

    // STEP 1: local preview (same style as Step 3)
    notifier.addImage(type: "nin", path: picked.path);

    // STEP 2: upload
    final url = await uploadToCloudinary(picked);

    // STEP 3: replace with cloud URL
    if (url != null) {
      notifier.addImage(type: "nin", path: url);
    }
  }

  ImageProvider getImage(String path) {
    return path.startsWith('http')
        ? NetworkImage(path)
        : FileImage(File(path)) as ImageProvider;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(technicianSignupController);
    final notifier = ref.read(technicianSignupController.notifier);

    final ninImage = state.ninImage;

    return Scaffold(
      appBar: AppBar(title: const Text("Upload NIN / ID")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "NIN / ID Card",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: ninImage == null || ninImage.isEmpty ? 1 : 1,
                    itemBuilder: (context, index) {
                      /// ADD BUTTON (ONLY WHEN EMPTY)
                      if (ninImage == null || ninImage.isEmpty) {
                        return GestureDetector(
                          onTap: pickAndUploadNin,
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
                                Icon(Icons.badge),
                                SizedBox(height: 8),
                                Text("Add NIN"),
                              ],
                            ),
                          ),
                        );
                      }

                      /// IMAGE CARD (LIKE STEP 3)
                      return Stack(
                        children: [
                          Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: getImage(ninImage),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          Positioned(
                            top: 6,
                            right: 16,
                            child: GestureDetector(
                              onTap: () {
                                notifier.addImage(
                                  type: "nin",
                                  path: "",
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
              ],
            ),

            const SizedBox(height: 25),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: acceptedLegal,
                  onChanged: (value) {
                    setState(() {
                      acceptedLegal = value ?? false;
                    });
                  },
                ),

                Expanded(
                  child: Wrap(
                    children: [
                      const Text("By continuing, you agree to KwikPro's "),

                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PrivacyPolicy(),
                            ),
                          );
                        },
                        child: const Text(
                          "Privacy Policy",
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),

                      const Text(" and "),

                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TermsAndConditions(),
                            ),
                          );
                        },
                        child: const Text(
                          "Terms & Conditions",
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Text(
              "We respect your privacy. Your data is used only to connect you with nearby technicians.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const Spacer(),

            const SizedBox(height: 20),


            ElevatedButton(
              onPressed: (acceptedLegal &&
                  ninImage != null &&
                  ninImage.isNotEmpty)
                  ? () => notifier.submit(context, ref)
                  : null,
              child: state.isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Finish"),
            ),
          ],
        ),
      ),
    );
  }
}