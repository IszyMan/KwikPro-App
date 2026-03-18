import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../onboarding/welcome_screen.dart';
import '../user/user_home_screen.dart';
import '../technician/technician_home_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));

    // ✅ Get the currently authenticated Firebase user
    final firebaseUser = ref.read(authServiceProvider).getCurrentUser();

    if (firebaseUser == null) {
      // 🔹 Not logged in → go to Welcome Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
      return;
    }

    // ✅ Fetch user profile from Firestore
    final firestore = ref.read(firestoreServiceProvider);
    final user = await firestore.getUser(firebaseUser.uid);

    if (user == null) {
      // 🔹 User record not found → go to Welcome Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
      return;
    }

    // ✅ Save user in Riverpod state
    ref.read(authProvider.notifier).setUser(user);

    // ✅ Navigate based on role
    if (user.role == 'user') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UserHomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TechnicianHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "KwikPro App - Connecting Users to Nearby Local Professionals",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}