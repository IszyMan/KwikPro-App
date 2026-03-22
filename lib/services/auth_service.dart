import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ConfirmationResult? _confirmationResult; // only for web

  /// Sends OTP:
  /// - Web: uses invisible reCAPTCHA (no visible popup for most users)
  /// - Mobile (Android): standard SMS flow with auto-detection possible
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      if (kIsWeb) {
        print("WEB FLOW - Phone: $phoneNumber");

        final verifier = RecaptchaVerifier(
          auth: FirebaseAuthPlatform.instance,  // ← This fixes the type error
          container: '',                         // Empty = aims for invisible/no visible widget
          size: RecaptchaVerifierSize.compact,   // Use compact (smallest visible option) or normal
          theme: RecaptchaVerifierTheme.light,
          // Optional debug callbacks
          onSuccess: () => print('reCAPTCHA solved'),
          onError: (FirebaseAuthException e) => print('reCAPTCHA error: ${e.message}'),
          onExpired: () => print('reCAPTCHA expired – retry needed'),
        );

        _confirmationResult = await _auth.signInWithPhoneNumber(
          phoneNumber,
          verifier,
        );

        onCodeSent('web');  // or onCodeSent(_confirmationResult.verificationId ?? 'web');
      } else {
        print("MOBILE FLOW - Phone: $phoneNumber");

        await _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Auto-verification (SMS read automatically on Android)
            await _auth.signInWithCredential(credential);
            // Optionally notify UI of success here
          },
          verificationFailed: (FirebaseAuthException e) {
            onError(e.message ?? 'Verification failed');
          },
          codeSent: (String verificationId, int? resendToken) {
            onCodeSent(verificationId);
          },
          timeout: const Duration(seconds: 60),
          codeAutoRetrievalTimeout: (String verificationId) {
            // Optional: trigger resend UI
          },
        );
      }
    } catch (e, stack) {
      print("sendOtp error: $e");
      print(stack);
      onError(e.toString());
    }
  }

  /// Verifies the OTP
  Future<UserCredential> verifyOtp({
    required String smsCode,
    String? verificationId, // required on mobile, ignored on web
  }) async {
    if (kIsWeb) {
      if (_confirmationResult == null) {
        throw Exception('No confirmation result. Call sendOtp first.');
      }
      return await _confirmationResult!.confirm(smsCode);
    } else {
      if (verificationId == null || verificationId.isEmpty) {
        throw Exception('verificationId required on mobile');
      }
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(credential);
    }
  }

  // signOut, currentUser, etc. remain the same
  Future<void> signOut() async => await _auth.signOut();

  User? get currentUser => _auth.currentUser;
}