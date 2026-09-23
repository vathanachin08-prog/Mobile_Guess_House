import 'package:flutter/material.dart';
import '../models/rental/room_model.dart';
import 'app_colors.dart';

class RoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;
  final bool isOwnerView;

  const RoomCard({
    super.key,
    required this.room,
    this.onTap,
    this.onMoreTap,
    this.isOwnerView = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = room.available ?? true;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Door / Room icon container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAvailable ? AppColors.primarySoft : AppColors.accentOrangeLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.meeting_room_outlined,
                color: isAvailable ? AppColors.primary : AppColors.accentOrange,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Middle info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        room.roomNumber ?? "Room",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (room.floor != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          "ជាន់ទី ${room.floor}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (room.roomType != null) ...[
                        Text(
                          room.roomType!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Text(" • ", style: TextStyle(color: AppColors.textMuted)),
                      ],
                      if (room.price != null)
                        Text(
                          "\$${room.price!.toStringAsFixed(0)} / mo",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                  if (room.facilities != null && room.facilities!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: room.facilities!.take(3).map((f) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            f.name ?? '',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Trailing status & menu
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isOwnerView && onMoreTap != null)
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary, size: 20),
                    onPressed: onMoreTap,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAvailable ? AppColors.primarySoft : AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAvailable ? "ទំនេរ" : "មានមនុស្ស",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isAvailable ? AppColors.primary : AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
