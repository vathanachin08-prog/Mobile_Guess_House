import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/language_service.dart';
import '../../../routes/app_route_name.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/custom_app_bar.dart';
import '../membership/owner_membership_view.dart';
import '../pricing/owner_pricing_view.dart';
import 'owner_profile_controller.dart';

class OwnerProfileView extends GetView<OwnerProfileController> {
  const OwnerProfileView({super.key});

  void _showImageSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'change_avatar'.tr,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                ),
                title: Text('take_photo'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('use_camera'.tr),
                onTap: () => controller.pickAndUploadImage(ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.photo_library_outlined, color: Colors.blue.shade700),
                ),
                title: Text('choose_gallery'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('select_from_device'.tr),
                onTap: () => controller.pickAndUploadImage(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarWidget() {
    return Obx(() {
      final path = controller.profileImagePath.value;
      return Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySoft,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: ClipOval(
              child: _buildAvatarImage(path),
            ),
          ),
          if (controller.isUploading.value)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.4),
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
          ),
        ],
      );
    });
  }

  Widget _buildAvatarImage(String path) {
    if (path.isEmpty) {
      return const Icon(Icons.business_center_rounded, size: 40, color: AppColors.primary);
    }
    if (path.startsWith('data:image')) {
      try {
        final base64Part = path.split(',').last;
        return Image.memory(base64Decode(base64Part), fit: BoxFit.cover, width: 80, height: 80);
      } catch (_) {
        return const Icon(Icons.business_center_rounded, size: 40, color: AppColors.primary);
      }
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: 80,
        height: 80,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.business_center_rounded, size: 40, color: AppColors.primary),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          );
        },
      );
    }
    if (!kIsWeb) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover, width: 80, height: 80);
      }
    }
    return const Icon(Icons.business_center_rounded, size: 40, color: AppColors.primary);
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<OwnerProfileController>()) {
      Get.put(OwnerProfileController());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadUser();
      controller.fetchProfileFromServer();
    });

    return Obx(() {
      // Reactive dependency on locale
      LanguageService.currentLocale.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: 'my_profile'.tr,
          subtitle: 'owner_profile'.tr,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Owner Profile Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showImageSourceSheet(context),
                      child: _buildAvatarWidget(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.displayName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            controller.phone,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'business_owner'.tr,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Business Properties Summary Row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('building_label'.tr, "1 ${'units'.tr}"),
                    Container(width: 1, height: 26, color: AppColors.border),
                    _buildStatItem('location_label'.tr, 'building_location'.tr),
                    Container(width: 1, height: 26, color: AppColors.border),
                    _buildStatItem('plan_label'.tr, 'membership_plan_free'.tr),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Management Section
              _buildSection(
                title: 'business_management'.tr,
                children: [
                  _buildListTile(
                    icon: Icons.calendar_month_rounded,
                    title: 'visit_requests'.tr,
                    onTap: () => Get.toNamed(AppRouteName.ownerVisitRequests),
                  ),
                  _buildListTile(
                    icon: Icons.tune_rounded,
                    title: 'pricing_utilities'.tr,
                    onTap: () => Get.to(() => const OwnerPricingView()),
                  ),
                  _buildListTile(
                    icon: Icons.workspace_premium_outlined,
                    title: 'membership_plan'.tr,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Free",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                      ),
                    ),
                    onTap: () => Get.to(() => const OwnerMembershipView()),
                  ),
                  _buildListTile(
                    icon: Icons.qr_code_2_rounded,
                    title: 'bakong_payment'.tr,
                    onTap: () => Get.to(() => const OwnerPricingView()),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // App Settings
              _buildSection(
                title: 'settings'.tr,
                children: [
                  _buildListTile(
                    icon: Icons.language,
                    title: 'language'.tr,
                    trailing: Text(
                      LanguageService.currentLanguageLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                    ),
                    onTap: () => LanguageService.showLanguageSelector(context),
                  ),
                  _buildListTile(
                    icon: Icons.support_agent_rounded,
                    title: 'help_support'.tr,
                    onTap: () {
                      Get.snackbar("Support", "Telegram support: @roomfinderkh_owner", backgroundColor: Colors.white);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Sign Out Button
              OutlinedButton.icon(
                onPressed: () {
                  Get.defaultDialog(
                    title: 'sign_out'.tr,
                    middleText: 'confirm_sign_out'.tr,
                    textConfirm: 'confirm'.tr,
                    textCancel: 'cancel'.tr,
                    confirmTextColor: Colors.white,
                    buttonColor: AppColors.danger,
                    onConfirm: () {
                      Get.back();
                      controller.logout();
                    },
                  );
                },
                icon: const Icon(Icons.logout, color: AppColors.danger, size: 20),
                label: Text(
                  'sign_out'.tr,
                  style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.dangerSoft),
                  backgroundColor: AppColors.dangerSoft.withValues(alpha: 0.3),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
