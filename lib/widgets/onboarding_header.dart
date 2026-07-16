import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class OnboardingHeader extends StatelessWidget {
  final Widget title;
  final String subtitle;

  const OnboardingHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        title,

        const SizedBox(height: 14),

        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textLight,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}