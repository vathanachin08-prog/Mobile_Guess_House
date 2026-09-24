import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_route_name.dart';
import '../../widgets/app_colors.dart';
import '../../widgets/button_custom_widget.dart';
import '../../widgets/input_custom_widget.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              if (Get.locale?.languageCode == 'km') {
                Get.updateLocale(const Locale('en', 'US'));
              } else {
                Get.updateLocale(const Locale('km', 'KH'));
              }
            },
            icon: const Icon(Icons.language, size: 18, color: AppColors.primary),
            label: Text(
              Get.locale?.languageCode == 'km' ? "ខ្មែរ" : "English",
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo & Header
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.home_work_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "RoomFinder KH",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "ចូលប្រើប្រាស់គណនីរបស់អ្នក / Sign in to your account",
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Form
                InputCustomWidget(
                  controller: controller.usernameController,
                  label: "លេខទូរស័ព្ទ / Phone Number",
                  hint: "012345678",
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                Obx(() => InputCustomWidget(
                  controller: controller.passwordController,
                  label: "ពាក្យសម្ងាត់ / Password",
                  hint: "••••••••",
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
                const SizedBox(height: 24),

                // Login Button
                Obx(() => ButtonCustomWidget(
                  isLoading: controller.isLoading.value,
                  title: "ចូលប្រើប្រាស់ / Sign In",
                  onTap: controller.onLogin,
                )),
                const SizedBox(height: 18),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "មិនទាន់មានគណនី? / No account? ",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    InkWell(
                      onTap: () => Get.toNamed(AppRouteName.register),
                      child: const Text(
                        "ចុះឈ្មោះ / Register",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Helper card for test credentials
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            "គណនីសាកល្បង / Test Credentials:",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              controller.usernameController.text = "012345678";
                              controller.passwordController.text = "password123";
                            },
                            child: const Text("Student (012345678)", style: TextStyle(fontSize: 11)),
                          ),
                          TextButton(
                            onPressed: () {
                              controller.usernameController.text = "098765432";
                              controller.passwordController.text = "password123";
                            },
                            child: const Text("Owner (098765432)", style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
