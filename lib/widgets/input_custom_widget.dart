import 'package:flutter/material.dart';
import 'app_colors.dart';
import '../core/services/language_service.dart';

class InputCustomWidget extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final String? label;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const InputCustomWidget({
    super.key,
    this.controller,
    this.hint,
    this.label,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
  });

  String? _getEffectiveHint() {
    if (hint != null && hint!.trim().isNotEmpty) {
      return hint;
    }
    if (label != null && label!.trim().isNotEmpty) {
      final l = label!.trim();
      final isKm = LanguageService.isKhmer;
      if (l.contains("ទូរស័ព្ទ") || l.toLowerCase().contains("phone")) {
        return isKm ? "បញ្ចូលលេខទូរស័ព្ទ..." : "Enter phone number...";
      }
      if (l.contains("បញ្ជាក់") || l.toLowerCase().contains("confirm")) {
        return isKm ? "បញ្ចូលពាក្យសម្ងាត់បញ្ជាក់..." : "Confirm your password...";
      }
      if (l.contains("ពាក្យសម្ងាត់") || l.toLowerCase().contains("password")) {
        return isKm ? "បញ្ចូលពាក្យសម្ងាត់..." : "Enter password...";
      }
      if (l.contains("អ៊ីមែល") || l.toLowerCase().contains("email")) {
        return isKm ? "បញ្ចូលអ៊ីមែល..." : "Enter email address...";
      }
      if (l.contains("នាមខ្លួន") || l.toLowerCase().contains("first name")) {
        return isKm ? "បញ្ចូលនាមខ្លួន..." : "Enter first name...";
      }
      if (l.contains("គោត្តនាម") || l.toLowerCase().contains("last name")) {
        return isKm ? "បញ្ចូលគោត្តនាម..." : "Enter last name...";
      }
      return isKm ? "បញ្ចូល$l..." : "Enter $l...";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveHint = _getEffectiveHint();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
          ],
          TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: effectiveHint,
              hintStyle: const TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
