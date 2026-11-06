import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import '../../core/services/api_service_impl.dart';
import '../../core/services/language_service.dart';
import '../../routes/app_route_name.dart';
import '../../widgets/animated_widgets.dart';
import '../../widgets/app_colors.dart';
import '../../widgets/button_custom_widget.dart';
import '../../widgets/input_custom_widget.dart';
import '../../widgets/server_config_dialog.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  LoginController get controller {
    if (Get.isRegistered<LoginController>()) {
      return Get.find<LoginController>();
    }
    final apiService = Get.isRegistered<ApiService>()
        ? Get.find<ApiService>()
        : Get.put<ApiService>(ApiServiceImpl(), permanent: true);
    return Get.put<LoginController>(LoginController(apiService: apiService));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      LanguageService.currentLocale.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.dns_rounded, color: AppColors.primary),
            tooltip: 'Server Settings',
            onPressed: () => ServerConfigDialog.show(context),
          ),
          actions: const [
            Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: AnimatedLanguageToggle(),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Official Brand Logo (Long press secretly fills admin for convenient dev testing)
                  GestureDetector(
                    onLongPress: () {
                      controller.usernameController.text = "admin";
                      controller.passwordController.text = "Admin@1234";
                    },
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: const BoxDecoration(
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'signin_to_account'.tr,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Form
                  InputCustomWidget(
                    controller: controller.usernameController,
                    label: 'phone'.tr,
                    hint: 'enter_phone'.tr,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  InputCustomWidget(
                    controller: controller.passwordController,
                    label: 'password'.tr,
                    hint: 'enter_password'.tr,
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
                  const SizedBox(height: 24),

                  // Login Button
                  ButtonCustomWidget(
                    isLoading: controller.isLoading.value,
                    title: 'login'.tr,
                    onTap: controller.onLogin,
                  ),
                  const SizedBox(height: 18),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () => Get.toNamed(AppRouteName.register),
                        child: Text(
                          'no_account'.tr,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
