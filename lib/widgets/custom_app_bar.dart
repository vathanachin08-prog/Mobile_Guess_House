import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../modules/owner/owner_main_controller.dart';
import 'app_colors.dart';
import 'owner_app_bar_helper.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final String? propertyDropdownText;
  final VoidCallback? onPropertyDropdownTap;
  final List<Widget>? actions;
  final Widget? leading;

  const CustomAppBar({
    super.key,
    this.title = "RoomFinder KH",
    String? propertyName,
    this.subtitle,
    this.showBack = false,
    this.onBack,
    String? propertyDropdownText,
    VoidCallback? onPropertyTap,
    VoidCallback? onPropertyDropdownTap,
    this.actions,
    this.leading,
  })  : propertyDropdownText = propertyDropdownText ?? propertyName,
        onPropertyDropdownTap = onPropertyDropdownTap ?? onPropertyTap;

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    // If actions are not provided on an owner screen (indicated by propertyDropdownText != null),
    // default to the standard interactive owner actions (Notification + Acc).
    final effectiveActions = actions ??
        (propertyDropdownText != null ? OwnerAppBarHelper.buildStandardActions(context) : null);

    final effectiveOnPropertyTap = onPropertyDropdownTap ??
        () => OwnerAppBarHelper.showPropertyPicker(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              if (showBack)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
                  onPressed: onBack ?? () => Get.back(),
                )
              else if (leading != null)
                leading!
              else
                GestureDetector(
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Get.back();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.home_work_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (propertyDropdownText != null)
                InkWell(
                  onTap: effectiveOnPropertyTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.home_outlined, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        _buildPropertyDropdownLabel(),
                        const SizedBox(width: 4),
                        const Icon(Icons.unfold_more, size: 14, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ...?effectiveActions,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyDropdownLabel() {
    if (Get.isRegistered<OwnerMainController>()) {
      final ctrl = Get.find<OwnerMainController>();
      return Obx(() {
        final text = ctrl.selectedPropertyShortName.value.isNotEmpty
            ? ctrl.selectedPropertyShortName.value
            : (propertyDropdownText ?? "My Home");
        return Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        );
      });
    }

    return Text(
      propertyDropdownText ?? "My Home",
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
