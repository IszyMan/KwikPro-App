import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwikpro/screens/technician/technician_signup_screen.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../user/user_home_screen.dart';
import '../technician/technician_home_screen.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
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

      // 🔥 VERIFY OTP
      final result = await authService.verifyOtp(
        verificationId: widget.verificationId,
        smsCode: code,
      );

      final firebaseUser = result.user;

      if (firebaseUser == null) {
        throw Exception("User is null");
      }

      // 🔹 HERE: CHECK FIRESTORE
      final doc = await ref.read(firestoreServiceProvider).getUser(firebaseUser.uid);

      if (doc != null) {
        // EXISTING USER → LOGIN
        ref.read(authProvider.notifier).setUser(doc);
      } else {
        // NEW USER → CREATE
        final role = ref.read(authProvider).role ?? 'user';

        final newUser = UserModel(
          uid: firebaseUser.uid,
          phone: firebaseUser.phoneNumber ?? '',
          role: role,
        );

        await ref.read(firestoreServiceProvider).saveUser(newUser);
        ref.read(authProvider.notifier).setUser(newUser);
      }

      setState(() => isLoading = false);

      // 🔹 NAVIGATE BASED ON ROLE
      final role = ref.read(authProvider).role ?? 'user';

      if (role == 'user') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const UserHomeScreen()),
              (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const TechnicianSignupScreen()),
              (route) => false,
        );
      }

    } catch (e) {
      setState(() => isLoading = false);
      print("ERROR: $e");
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
                hintText: "123456",
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