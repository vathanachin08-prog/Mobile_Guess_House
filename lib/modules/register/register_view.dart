import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/app_colors.dart';
import '../../widgets/button_custom_widget.dart';
import '../../widgets/input_custom_widget.dart';
import 'register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "ចុះឈ្មោះគណនី / Register",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Role Selector Header
              const Text(
                "ជ្រើសរើសតួនាទី / Select Account Type",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              Obx(() => Row(
                children: [
                  Expanded(
                    child: _buildRoleCard(
                      title: "និស្សិត / Student",
                      subtitle: "ស្វែងរកបន្ទប់ជួល",
                      icon: Icons.school_outlined,
                      role: "STUDENT",
                      isSelected: controller.selectedRole.value == "STUDENT",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRoleCard(
                      title: "ម្ចាស់ផ្ទះ / Owner",
                      subtitle: "គ្រប់គ្រងបន្ទប់ជួល",
                      icon: Icons.business_outlined,
                      role: "OWNER",
                      isSelected: controller.selectedRole.value == "OWNER",
                    ),
                  ),
                ],
              )),
              const SizedBox(height: 24),

              // Form fields
              Row(
                children: [
                  Expanded(
                    child: InputCustomWidget(
                      controller: controller.firstNameController,
                      label: "នាមត្រកូល / First Name",
                      hint: "Vathana",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InputCustomWidget(
                      controller: controller.lastNameController,
                      label: "នាមខ្លួន / Last Name",
                      hint: "Chin",
                    ),
                  ),
                ],
              ),
              InputCustomWidget(
                controller: controller.phoneController,
                label: "លេខទូរស័ព្ទ / Phone Number",
                hint: "012345678",
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
              ),
              InputCustomWidget(
                controller: controller.emailController,
                label: "អ៊ីមែល / Email Address",
                hint: "student@example.com",
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
              ),
              Obx(() => InputCustomWidget(
                controller: controller.passwordController,
                label: "ពាក្យសម្ងាត់ / Password",
                hint: "យ៉ាងហោចណាស់ ៦ តួអក្សរ",
                obscureText: controller.obscurePassword.value,
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.obscurePassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: controller.togglePasswordVisibility,
                ),
              )),
              Obx(() => InputCustomWidget(
                controller: controller.confirmPasswordController,
                label: "ផ្ទៀងផ្ទាត់ពាក្យសម្ងាត់ / Confirm Password",
                hint: "បញ្ចូលពាក្យសម្ងាត់ម្តងទៀត",
                obscureText: controller.obscurePassword.value,
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
              )),
              const SizedBox(height: 28),

              // Submit Button
              Obx(() => ButtonCustomWidget(
                isLoading: controller.isLoading.value,
                title: "បង្កើតគណនី / Create Account",
                onTap: controller.onRegister,
              )),
              const SizedBox(height: 18),

              // Back to Login
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "មានគណនីរួចហើយ? / Already have an account? ",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    InkWell(
                      onTap: () => Get.back(),
                      child: const Text(
                        "ចូលប្រើ / Sign In",
                        style: TextStyle(
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
