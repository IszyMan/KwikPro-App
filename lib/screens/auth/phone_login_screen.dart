import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import 'otp_screen.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  final String role;
  const PhoneLoginScreen({super.key, required this.role});

  @override
  ConsumerState<PhoneLoginScreen> createState() =>
      _PhoneLoginScreenState();
}

class _PhoneLoginScreenState
    extends ConsumerState<PhoneLoginScreen> {

  final TextEditingController phoneController =
  TextEditingController();

  bool isLoading = false;

  void _sendOtp() async {
    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter phone number")),
      );
      return;
    }

    setState(() => isLoading = true);

    final authService = ref.read(authServiceProvider);

    await authService.sendOtp(
      phoneNumber: phone,
      onCodeSent: (verificationId) {
        setState(() => isLoading = false);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              verificationId: verificationId,
              phoneNumber: phone,
              role: widget.role,
            ),
          ),
        );
      },
      onError: (error) {
        setState(() => isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Phone Login"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 40),

            const Text(
              "Enter your phone number",
              style: TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter phone number",
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 100,
              child: Center(child: Text("")),
            ),

            Container(
              key: const Key("recaptcha-container"),
              height: 0,
              width: 0,

            ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _sendOtp,
                child: isLoading
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
                    : const Text("Continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}