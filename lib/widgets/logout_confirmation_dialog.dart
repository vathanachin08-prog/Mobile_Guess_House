import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_clean_dialog.dart';
import 'app_colors.dart';

class LogoutConfirmationDialog {
  LogoutConfirmationDialog._();

  static void show(BuildContext context, {required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AppCleanDialog(
        title: 'sign_out'.tr,
        subtitle: 'confirm_sign_out'.tr,
        maxWidth: 380,
        icon: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.dangerSoft.withValues(alpha: 0.65),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.dangerSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.danger,
                size: 22,
              ),
            ),
          ),
        ),
        content: const SizedBox(height: 6),
        confirmText: 'sign_out'.tr,
        confirmColor: AppColors.danger,
        cancelText: 'cancel'.tr,
        onConfirm: () {
          Navigator.pop(ctx);
          onConfirm();
        },
      ),
    );
  }
}
