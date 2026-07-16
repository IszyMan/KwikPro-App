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
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),

                const AppLogo(size: 90),

                const SizedBox(height: 28),

                const OnboardingHeader(
                  title: Text(
                    "Choose Your Account",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      height: 1.2,
                    ),
                  ),
                  subtitle: "Select how you would like to use KwikPro.",
                ),

                const SizedBox(height: 40),

                AppOptionCard(
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

                const SizedBox(height: 22),

                AppOptionCard(
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

                const Spacer(),

                const Divider(),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: AppColors.textLight,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Your information is secure and protected.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}