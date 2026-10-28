import 'dart:convert';
import 'package:flutter/material.dart';
import '../constants/constant_uri.dart';
import 'app_colors.dart';

class ChatAvatarWidget extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double size;
  final bool isOwner;
  final bool showOnlineBadge;

  const ChatAvatarWidget({
    super.key,
    required this.name,
    this.avatarUrl,
    this.size = 48,
    this.isOwner = false,
    this.showOnlineBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = size / 2;

    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: isOwner ? Colors.blue.shade100 : AppColors.primarySoft,
      child: Text(
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : "U",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.72,
          color: isOwner ? Colors.blue.shade800 : AppColors.primary,
        ),
      ),
    );

    Widget avatarImageWidget = fallback;
    final trimmed = avatarUrl?.trim();

    if (trimmed != null && trimmed.isNotEmpty) {
      if (trimmed.startsWith('data:image')) {
        try {
          final base64Part = trimmed.split(',').last;
          avatarImageWidget = ClipOval(
            child: Image.memory(
              base64Decode(base64Part),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
          );
        } catch (_) {
          avatarImageWidget = fallback;
        }
      } else {
        final fullUrl = trimmed.startsWith('http')
            ? trimmed
            : "${ConstantUri.baseUri}/api/public/view/image?filename=$trimmed";

        avatarImageWidget = ClipOval(
          child: Image.network(
            fullUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          ),
        );
      }
    }

    if (!showOnlineBadge) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isOwner ? Colors.blue.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: avatarImageWidget,
      );
    }

    final badgeSize = (size * 0.26).clamp(8.0, 14.0);

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isOwner ? Colors.blue.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: avatarImageWidget,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
