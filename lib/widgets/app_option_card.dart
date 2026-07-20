import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppOptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color background;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const AppOptionCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    // Scales between 85% and 100%
    final scale = (screenHeight / 850).clamp(0.85, 1.0);

    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(20 * scale),
      child: InkWell(
        borderRadius: BorderRadius.circular(20 * scale),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(20 * scale),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20 * scale),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64 * scale,
                height: 64 * scale,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 32 * scale,
                ),
              ),

              SizedBox(width: 16 * scale),

              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 19 * scale,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),

                    SizedBox(height: 6 * scale),

                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 14 * scale,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 10 * scale),

              Container(
                width: 32 * scale,
                height: 32 * scale,
                decoration: const BoxDecoration(
                  color: AppColors.lightBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15 * scale,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}