import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppProgressHeader extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  const AppProgressHeader({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final progress = step / totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        if (onBack != null)
          IconButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new),
          ),

        const SizedBox(height: 10),

        Text(
          "Step $step of $totalSteps",
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(
              AppColors.primary,
            ),
          ),
        ),

        const SizedBox(height: 26),

        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textLight,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}