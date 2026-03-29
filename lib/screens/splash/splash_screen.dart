import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../onboarding/account_type_screen.dart';
import '../onboarding/welcome_screen.dart';
import '../technician/technician_dashboard.dart';
import '../technician/technician_main_screen.dart';
import '../user/user_main_screen.dart';
import '../user/user_signup_screen.dart';
import '../technician/technician_home_screen.dart';
import '../technician/technician_signup_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  final String? role;
  const SplashScreen({super.key, this.role});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndProfile();
  }

  Future<void> _checkAuthAndProfile() async {
    await Future.delayed(const Duration(seconds: 2));

    final firebaseUser = ref.read(authServiceProvider).currentUser;
    if (firebaseUser == null) {
      _navigateTo(const WelcomeScreen());
      return;
    }

    final db = FirebaseFirestore.instance;

    final selectedRole = widget.role ?? ref.read(authProvider).role;

    final techSnap = await db.collection('technicians').doc(firebaseUser.uid).get();
    final userSnap = await db.collection('users').doc(firebaseUser.uid).get();

//  CASE 1: BOTH EXIST
    if (techSnap.exists && userSnap.exists) {
      if (selectedRole == 'technician') {
        _navigateTo(const TechnicianMainScreen());
      } else {
        _navigateTo(const UserMainScreen());
      }
      return;
    }

//  CASE 2: ONLY TECH EXISTS
    if (techSnap.exists && !userSnap.exists) {
      if (selectedRole == 'user') {
        _showSwitchDialog(isTechnician: true);
        return;
      } else {
        _navigateTo(const TechnicianMainScreen());
        return;
      }
    }

//  CASE 3: ONLY USER EXISTS
    if (userSnap.exists && !techSnap.exists) {
      if (selectedRole == 'technician') {
        _showSwitchDialog(isTechnician: false);
        return;
      } else {
        _navigateTo(const UserMainScreen());
        return;
      }
    }

//  CASE 4: NEW USER
    if (selectedRole == 'technician') {
      _navigateTo(const TechnicianSignupScreen());
    } else if (selectedRole == 'user') {
      _navigateTo(const UserSignupScreen());
    } else {
      _navigateTo(const AccountTypeScreen());
    }

  }

  void _navigateTo(Widget destination) {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  void _showSwitchDialog({required bool isTechnician}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Account Exists"),
        content: Text(
          isTechnician
              ? "This number is already registered as a Technician. Do you want to continue as Technician or create a User account?"
              : "This number is already registered as a User. Do you want to continue as User or create a Technician account?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              // Continue existing
              if (isTechnician) {
                _navigateTo(const TechnicianMainScreen());
              } else {
                _navigateTo(const UserMainScreen());
              }
            },
            child: const Text("Continue Existing"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              // Create new role
              if (isTechnician) {
                _navigateTo(const UserSignupScreen());
              } else {
                _navigateTo(const TechnicianSignupScreen());
              }
            },
            child: const Text("Create New"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build_circle_outlined, size: 100, color: Colors.blue),
            SizedBox(height: 32),
            Text(
              "KwikPro",
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Connecting Users to Nearby Repair Professionals",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}