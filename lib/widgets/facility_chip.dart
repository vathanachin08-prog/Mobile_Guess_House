import 'package:flutter/material.dart';
import '../core/services/language_service.dart';
import 'app_colors.dart';

class FacilityChip extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback? onTap;

  const FacilityChip({
    super.key,
    required this.name,
    this.isSelected = false,
    this.onTap,
  });

  IconData _getIcon(String n) {
    final lower = n.toLowerCase();
    if (lower.contains('wifi')) return Icons.wifi;
    if (lower.contains('air') || lower.contains('ac')) return Icons.ac_unit;
    if (lower.contains('bath')) return Icons.bathtub_outlined;
    if (lower.contains('park')) return Icons.local_parking;
    if (lower.contains('kitch')) return Icons.kitchen;
    if (lower.contains('wash')) return Icons.local_laundry_service;
    if (lower.contains('secur')) return Icons.shield_outlined;
    if (lower.contains('furn')) return Icons.chair_outlined;
    return Icons.check_circle_outline;
  }

  String _formatName(String n) {
    final lower = n.toLowerCase();
    if (LanguageService.isKhmer) {
      if (lower.contains('wifi')) return 'វ៉ាយហ្វាយ (WiFi)';
      if (lower.contains('air') || lower.contains('ac')) return 'ម៉ាស៊ីនត្រជាក់';
      if (lower.contains('bath')) return 'បន្ទប់ទឹកផ្ទាល់ខ្លួន';
      if (lower.contains('park')) return 'ចំណតយានយន្ត';
      if (lower.contains('kitch')) return 'ចង្ក្រានបាយ';
      if (lower.contains('wash')) return 'ម៉ាស៊ីនបោកគក់';
      if (lower.contains('secur')) return 'សន្តិសុខ / CCTV';
      if (lower.contains('furn')) return 'គ្រឿងសង្ហារិម';
    }
    return n.replaceAll('_', ' ').toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIcon(name),
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              _formatName(name),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
