import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../widgets/app_colors.dart';

class LanguageService {
  LanguageService._();

  static const String storageKey = 'SELECTED_LANGUAGE_CODE';

  static const Locale khmerLocale = Locale('km', 'KH');
  static const Locale englishLocale = Locale('en', 'US');

  /// Get the initially saved locale or default to Khmer
  static Locale getInitialLocale() {
    try {
      final box = GetStorage();
      final savedCode = box.read<String>(storageKey);
      if (savedCode == 'en') {
        return englishLocale;
      }
      return khmerLocale;
    } catch (_) {
      return khmerLocale;
    }
  }

  static final Rx<Locale> currentLocale = getInitialLocale().obs;

  /// Check whether current locale is Khmer
  static bool get isKhmer {
    return currentLocale.value.languageCode == 'km';
  }

  /// Get display name of current language
  static String get currentLanguageLabel {
    return isKhmer ? "ខ្មែរ (KH)" : "English (US)";
  }

  /// Switch to specific language
  static Future<void> switchLanguage(String langCode) async {
    final targetLocale = (langCode == 'en') ? englishLocale : khmerLocale;
    final box = GetStorage();
    await box.write(storageKey, langCode);
    currentLocale.value = targetLocale;
    await Get.updateLocale(targetLocale);

    Get.snackbar(
      langCode == 'en' ? "Language Changed" : "ការផ្លាស់ប្តូរភាសា",
      langCode == 'en' ? "Language switched to English" : "ភាសាត្រូវបានប្តូរទៅជា ភាសាខ្មែរ",
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.white,
      colorText: AppColors.primary,
      icon: const Icon(Icons.language, color: AppColors.primary),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  /// Quick toggle between Khmer and English
  static Future<void> toggleLanguage() async {
    if (isKhmer) {
      await switchLanguage('en');
    } else {
      await switchLanguage('km');
    }
  }

  /// Show language selection dialog / modal sheet
  static void showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.language, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'select_language'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLanguageOption(
                  ctx: ctx,
                  code: 'km',
                  title: 'ភាសាខ្មែរ (Khmer)',
                  subtitle: 'ប្រើប្រាស់ជាភាសាខ្មែរ',
                  flag: '🇰🇭',
                  isSelected: isKhmer,
                ),
                const SizedBox(height: 10),
                _buildLanguageOption(
                  ctx: ctx,
                  code: 'en',
                  title: 'English (US)',
                  subtitle: 'Use English language',
                  flag: '🇺🇸',
                  isSelected: !isKhmer,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildLanguageOption({
    required BuildContext ctx,
    required String code,
    required String title,
    required String subtitle,
    required String flag,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(ctx);
        switchLanguage(code);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22)
            else
              const Icon(Icons.radio_button_unchecked_rounded, color: AppColors.border, size: 22),
          ],
        ),
      ),
    );
  }
}
