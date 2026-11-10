import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import '../../core/services/api_service_impl.dart';
import '../../core/services/language_service.dart';
import '../../widgets/app_colors.dart';
import '../../widgets/button_custom_widget.dart';
import '../../widgets/input_custom_widget.dart';
import 'register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  RegisterController get controller {
    if (Get.isRegistered<RegisterController>()) {
      return Get.find<RegisterController>();
    }
    final apiService = Get.isRegistered<ApiService>()
        ? Get.find<ApiService>()
        : Get.put<ApiService>(ApiServiceImpl(), permanent: true);
    return Get.put<RegisterController>(RegisterController(apiService: apiService));
  }

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
              tooltip: LanguageService.isKhmer ? "ជ្រើសរើសភាសា" : "Select Language",
              icon: const Icon(
                Icons.public_rounded,
                color: AppColors.textPrimary,
                size: 22,
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
                        hint: 'enter_first_name'.tr,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InputCustomWidget(
                        controller: controller.lastNameController,
                        label: 'last_name'.tr,
                        hint: 'enter_last_name'.tr,
                      ),
                    ),
                  ],
                ),
                InputCustomWidget(
                  controller: controller.phoneController,
                  label: 'phone'.tr,
                  hint: 'enter_phone'.tr,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                ),
                InputCustomWidget(
                  controller: controller.emailController,
                  label: LanguageService.isKhmer ? "អ៊ីមែល" : "Email Address",
                  hint: LanguageService.isKhmer ? "បញ្ចូលអ៊ីមែល..." : "Enter email address...",
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                ),
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
                InputCustomWidget(
                  controller: controller.confirmPasswordController,
                  label: 'confirm_password'.tr,
                  hint: 'enter_confirm_password'.tr,
                  obscureText: controller.obscurePassword.value,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                ),

                // If OWNER is selected, show owner & property information fields
                if (controller.selectedRole.value == "OWNER") ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.apartment_rounded, color: Color(0xFF00A86B), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              LanguageService.isKhmer ? "ព័ត៌មានអគារ ឬផ្ទះជួល (Owner Details)" : "Property & Owner Information",
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF065F46),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          LanguageService.isKhmer
                              ? "សូមបំពេញព័ត៌មានអគាររបស់អ្នក ដើម្បីបញ្ជូនទៅកាន់ Web Admin ត្រួតពិនិត្យ និងអនុម័ត។"
                              : "Please complete your property details for Web Admin verification and approval.",
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF047857), height: 1.3),
                        ),
                        const SizedBox(height: 14),
                        InputCustomWidget(
                          controller: controller.propertyNameController,
                          label: LanguageService.isKhmer ? "ឈ្មោះអគារ ឬបន្ទប់ជួល *" : "Property / Dorm Name *",
                          hint: LanguageService.isKhmer ? "ឧ. BBU Student Residence" : "e.g. BBU Student Residence",
                          prefixIcon: const Icon(Icons.home_work_outlined, color: AppColors.textSecondary),
                        ),
                        InputCustomWidget(
                          controller: controller.addressController,
                          label: LanguageService.isKhmer ? "ទីតាំង ឬអាសយដ្ឋាន *" : "Address / Location *",
                          hint: LanguageService.isKhmer ? "ឧ. ក្រុងសៀមរាប ជិតសាកលវិទ្យាល័យ BBU" : "e.g. Krong Siem Reap, Near BBU",
                          prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textSecondary),
                        ),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: InputCustomWidget(
                                controller: controller.idCardController,
                                label: LanguageService.isKhmer ? "លេខអត្តសញ្ញាណប័ណ្ណ" : "National ID / License",
                                hint: "012345678",
                                keyboardType: TextInputType.number,
                                prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.textSecondary),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: InputCustomWidget(
                                controller: controller.totalRoomsController,
                                label: LanguageService.isKhmer ? "ចំនួនបន្ទប់" : "Total Rooms",
                                hint: "8",
                                keyboardType: TextInputType.number,
                                prefixIcon: const Icon(Icons.meeting_room_outlined, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // Submit Button
                ButtonCustomWidget(
                  isLoading: controller.isLoading.value,
                  title: controller.selectedRole.value == "OWNER"
                      ? (LanguageService.isKhmer ? "បញ្ជូនព័ត៌មានទៅកាន់ Admin" : "Submit to Web Admin")
                      : (LanguageService.isKhmer ? "បង្កើតគណនី និងចូលប្រើ" : "Register & Start Exploring"),
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
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 26,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white.withValues(alpha: 0.9) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
