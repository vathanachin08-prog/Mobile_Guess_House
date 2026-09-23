import 'package:flutter/material.dart';
import 'app_colors.dart';

class ButtonCustomWidget extends StatelessWidget {
  final bool? isLoading;
  final String? title;
  final VoidCallback? onTap;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;

  const ButtonCustomWidget({
    super.key,
    this.isLoading,
    this.title,
    this.onTap,
    this.onPressed,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final callback = onTap ?? onPressed;
    return InkWell(
      onTap: isLoading == true ? null : callback,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color ?? AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        width: double.infinity,
        child: Center(
          child: isLoading == true
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      title ?? "",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
