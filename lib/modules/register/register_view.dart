import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/language_service.dart';
import '../../widgets/app_colors.dart';
import '../../widgets/button_custom_widget.dart';
import '../../widgets/input_custom_widget.dart';
import 'register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Rebuild reactively when language changes
      LanguageService.currentLocale.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'register'.tr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
            onPressed: () => Get.back(),
          ),
          actions: [
            IconButton(
              tooltip: 'switch_language'.tr,
              icon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language, color: AppColors.primary, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      LanguageService.isKhmer ? "KH" : "EN",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              onPressed: () => LanguageService.showLanguageSelector(context),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Role Selector Header
                Text(
                  'select_account_type'.tr,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildRoleCard(
                        title: 'student'.tr,
                        subtitle: LanguageService.isKhmer ? "ស្វែងរកបន្ទប់ជួល" : "Find rental rooms",
                        icon: Icons.school_outlined,
                        role: "STUDENT",
                        isSelected: controller.selectedRole.value == "STUDENT",
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRoleCard(
                        title: 'owner'.tr,
                        subtitle: LanguageService.isKhmer ? "គ្រប់គ្រងបន្ទប់ជួល" : "Manage properties",
                        icon: Icons.business_outlined,
                        role: "OWNER",
                        isSelected: controller.selectedRole.value == "OWNER",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Form fields
                Row(
                  children: [
                    Expanded(
                      child: InputCustomWidget(
                        controller: controller.firstNameController,
                        label: 'first_name'.tr,
                        hint: "Vathana",
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InputCustomWidget(
                        controller: controller.lastNameController,
                        label: 'last_name'.tr,
                        hint: "Chin",
                      ),
                    ),
                  ],
                ),
                InputCustomWidget(
                  controller: controller.phoneController,
                  label: 'phone'.tr,
                  hint: "012345678",
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                ),
                InputCustomWidget(
                  controller: controller.emailController,
                  label: LanguageService.isKhmer ? "អ៊ីមែល" : "Email Address",
                  hint: "student@example.com",
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                ),
                InputCustomWidget(
                  controller: controller.passwordController,
                  label: 'password'.tr,
                  hint: LanguageService.isKhmer ? "យ៉ាងហោចណាស់ ៦ តួអក្សរ" : "At least 6 characters",
                  obscureText: controller.obscurePassword.value,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.obscurePassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: controller.togglePasswordVisibility,
                  ),
                ),
                InputCustomWidget(
                  controller: controller.confirmPasswordController,
                  label: 'confirm_password'.tr,
                  hint: LanguageService.isKhmer ? "បញ្ចូលពាក្យសម្ងាត់ម្តងទៀត" : "Re-enter password",
                  obscureText: controller.obscurePassword.value,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 28),

                // Submit Button
                ButtonCustomWidget(
                  isLoading: controller.isLoading.value,
                  title: 'create_account'.tr,
                  onTap: controller.onRegister,
                ),
                const SizedBox(height: 18),

                // Back to Login
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        LanguageService.isKhmer ? "មានគណនីរួចហើយ? " : "Already have an account? ",
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      InkWell(
                        onTap: () => Get.back(),
                        child: Text(
                          'login'.tr,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String role,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => controller.selectedRole.value = role,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 26,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
