import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppSaveButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const AppSaveButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
