import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_colors.dart';

/// Reusable Clean & Simple Dialog component inspired by RoomFinder KH standard.
/// Features:
/// - Rounded 16-18px card with soft barrier
/// - Centered title and subtitle
/// - Top-right 'X' close button
/// - Full-width stacked primary action button (Green/Custom)
/// - Full-width stacked secondary action button (Outlined Cancel)
class AppCleanDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget content;
  final String confirmText;
  final VoidCallback onConfirm;
  final String? cancelText;
  final VoidCallback? onCancel;
  final Color? confirmColor;
  final bool isConfirmLoading;
  final double maxWidth;
  final bool showCloseButton;
  final Widget? icon;

  const AppCleanDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.content,
    required this.confirmText,
    required this.onConfirm,
    this.cancelText,
    this.onCancel,
    this.confirmColor,
    this.isConfirmLoading = false,
    this.maxWidth = 440,
    this.showCloseButton = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: AppColors.surface,
      elevation: 6,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Header with Centered Title & Top-Right Close Button
              Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          icon!,
                          const SizedBox(height: 10),
                        ],
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showCloseButton)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        splashRadius: 18,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // Content Body (Scrollable if content overflows viewport)
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: content,
                ),
              ),

              const SizedBox(height: 20),

              // Full-width Primary Action Button
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: isConfirmLoading ? null : onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor ?? AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isConfirmLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          confirmText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              // Full-width Outlined Cancel Button
              if (cancelText != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: onCancel ?? () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                    child: Text(
                      cancelText!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Show clean confirmation / delete dialog
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    Color? confirmColor,
    VoidCallback? onConfirm,
    Widget? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AppCleanDialog(
        title: title,
        icon: icon,
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ),
        confirmText: confirmText ?? 'confirm'.tr,
        cancelText: cancelText ?? 'cancel'.tr,
        confirmColor: confirmColor ?? AppColors.danger,
        onConfirm: () {
          Navigator.pop(ctx, true);
          onConfirm?.call();
        },
      ),
    );
  }
}
