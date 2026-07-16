import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppPrimaryButton extends StatelessWidget {

  final String text;

  final VoidCallback? onPressed;

  final bool loading;

  const AppPrimaryButton({

    super.key,

    required this.text,

    required this.onPressed,

    this.loading = false,

  });

  @override
  Widget build(BuildContext context) {

    return SizedBox(

      width: double.infinity,

      height: 58,

      child: ElevatedButton(

        onPressed: loading ? null : onPressed,

        style: ElevatedButton.styleFrom(

          backgroundColor: AppColors.primary,

          foregroundColor: Colors.white,

          elevation: 2,

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(16),

          ),

        ),

        child: loading

            ? const SizedBox(

          height: 22,

          width: 22,

          child: CircularProgressIndicator(

            strokeWidth: 2.5,

            color: Colors.white,

          ),

        )

            : Text(

          text,

          style: const TextStyle(

            fontWeight: FontWeight.bold,

            fontSize: 17,

          ),

        ),

      ),

    );
  }
}