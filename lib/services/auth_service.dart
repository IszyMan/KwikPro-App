//import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/*class AuthService {

  //FAKE SEND OTP
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(String error) onError,
}) async {
    await Future.delayed(const Duration(seconds: 2));

    //Always succeed
    codeSent("mock_verification_id");
}

  //  FAKE VERIFY OTP
  Future<dynamic> verifyOtp({
      required String verificationId,
      required String smsCode,
  }) async {
      await Future.delayed(const Duration(seconds: 1));

      //Accept ANY 6-Digit code
    if (smsCode.length == 6){
      return MockUser(
          uid: "12345",
          phoneNumber: "+2349034697450");
    }else {
      throw Exception("Invalid OTP!");
    }
  }

} */



class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseAuth get auth => _auth;

  // 🔥 SEND OTP
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(String error) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? "Verification failed");
        },
        codeSent: (String verificationId, int? resendToken) {
          codeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  // 🔥 VERIFY OTP
  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    return await _auth.signInWithCredential(credential);
  }

  // 🔥 GET CURRENT USER
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}