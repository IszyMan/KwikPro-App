import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../splash/splash_screen.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final String role;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    required this.role,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final TextEditingController otpController = TextEditingController();
  bool isLoading = false;

  void _verifyOtp() async {
    final code = otpController.text.trim();

    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid OTP")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);

      // VERIFY OTP
      final result = await authService.verifyOtp(
        verificationId: widget.verificationId,
        smsCode: code,
      );

      final firebaseUser = result.user;

      if (firebaseUser == null) {
        throw Exception("User is null");
      }

      //  Sync Firebase user into provider
      ref.read(authProvider.notifier).setUser(firebaseUser);

      setState(() => isLoading = false);

      // ALWAYS go to SplashScreen (it decides everything)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => SplashScreen(role: widget.role)),
            (route) => false,
      );

    } catch (e) {
      setState(() => isLoading = false);
      print("OTP ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify OTP"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),

            Text(
              "Enter code sent to ${widget.phoneNumber}",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "",
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _verifyOtp,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Verify"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}