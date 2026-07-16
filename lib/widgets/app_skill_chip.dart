import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppSkillChip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const AppSkillChip({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(text),
      selected: selected,
      selectedColor: AppColors.primary.withOpacity(.15),
      checkmarkColor: AppColors.primary,
      side: BorderSide(
        color: selected
            ? AppColors.primary
            : AppColors.border,
      ),
      onSelected: (_) => onTap(),
    );
  }
}