import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_option_card.dart';
import '../../widgets/onboarding_header.dart';
import '../auth/phone_login_screen.dart';

class AccountTypeScreen extends ConsumerWidget {
  const AccountTypeScreen({super.key});

  void _selectRole(
      BuildContext context,
      WidgetRef ref,
      String role,
      ) {
    ref.read(authProvider.notifier).setRole(role);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhoneLoginScreen(role: role),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive scaling (0.85 - 1.0)
    final scale = (screenHeight / 850).clamp(0.85, 1.0);

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF4F9FF),
                Colors.white,
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 22 * scale,
              vertical: 16 * scale,
            ),
            child: Column(
              children: [
                SizedBox(height: 8 * scale),

                AppLogo(
                  size: 75 * scale,
                ),

                SizedBox(height: 18 * scale),

                OnboardingHeader(
                  title: Text(
                    "Choose Your Account",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28 * scale,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      height: 1.15,
                    ),
                  ),
                  subtitle: "Select how you would like to use KwikPro.",
                ),

                SizedBox(height: 22 * scale),

                Expanded(
                  child: AppOptionCard(
                    icon: Icons.home_repair_service_rounded,
                    iconColor: AppColors.primary,
                    background: AppColors.cardBlue,
                    title: "I Need a Service",
                    subtitle:
                    "Book trusted technicians for repairs, installation and maintenance.",
                    onTap: () => _selectRole(
                      context,
                      ref,
                      "user",
                    ),
                  ),
                ),

                SizedBox(height: 14 * scale),

                Expanded(
                  child: AppOptionCard(
                    icon: Icons.handyman_rounded,
                    iconColor: Colors.green,
                    background: AppColors.cardGreen,
                    title: "I Offer Services",
                    subtitle:
                    "Receive job requests, connect with customers and grow your business.",
                    onTap: () => _selectRole(
                      context,
                      ref,
                      "technician",
                    ),
                  ),
                ),

                SizedBox(height: 18 * scale),

                const Divider(height: 1),

                SizedBox(height: 12 * scale),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 18 * scale,
                      color: AppColors.textLight,
                    ),
                    SizedBox(width: 8 * scale),
                    Expanded(
                      child: Text(
                        "Your information is secure and protected.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 13 * scale,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 6 * scale),
              ],
            ),
          ),
        ),
      ),
    );
  }
}