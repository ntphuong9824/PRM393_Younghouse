import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Reusable form field dùng chung cho tất cả form screens
class AppFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool required;
  final bool isNumber;
  final int maxLines;
  final String? Function(String?)? validator;

  const AppFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.required = true,
    this.isNumber = false,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      validator: validator ??
          (required
              ? (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập $label' : null
              : null),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}
