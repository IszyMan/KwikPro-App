import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../auth/phone_login_screen.dart';

class AccountTypeScreen extends ConsumerWidget {
  const AccountTypeScreen({super.key});

  void _selectRole(BuildContext context, WidgetRef ref, String role) {
    // Save role in Riverpod
    ref.read(authProvider.notifier).setRole(role);

    // Navigate to phone login
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PhoneLoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Account Type"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 30),

            // USER BUTTON
            _buildOptionCard(
              title: "I need a service",
              subtitle: "Hire technicians near you",
              icon: Icons.person,
              onTap: () => _selectRole(context, ref, "user"),
            ),

            const SizedBox(height: 20),

            // TECHNICIAN BUTTON
            _buildOptionCard(
              title: "I offer services",
              subtitle: "Get hired by customers",
              icon: Icons.build,
              onTap: () => _selectRole(context, ref, "technician"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40),

            const SizedBox(width: 20),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}