import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  static const primaryGradient = LinearGradient(
    colors: [
      AppColors.primary,
      AppColors.secondary,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
