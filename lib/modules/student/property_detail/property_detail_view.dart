import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/constant_uri.dart';
import '../../../routes/app_route_name.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/facility_chip.dart';
import '../../../widgets/room_card.dart';
import '../../../core/services/language_service.dart';
import '../visit_requests/request_visit_dialog.dart';
import 'property_detail_controller.dart';

class PropertyDetailView extends GetView<PropertyDetailController> {
  const PropertyDetailView({super.key});

  Widget _buildPropertyDetailImage(String? img) {
    if (img == null || img.trim().isEmpty) {
      return Center(
        child: Icon(
          Icons.apartment_rounded,
          size: 80,
          color: AppColors.primary.withValues(alpha: 0.4),
        ),
      );
    }
    if (img.startsWith('data:image')) {
      try {
        final base64Str = img.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => Center(
            child: Icon(
              Icons.apartment_rounded,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
          ),
        );
      } catch (_) {
        return Center(
          child: Icon(
            Icons.apartment_rounded,
            size: 80,
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
        );
      }
    }
    final fullUrl = img.startsWith('http')
        ? img
        : "${ConstantUri.baseUri}/api/public/view/image?filename=$img";
    return Image.network(
      fullUrl,
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, stack) => Center(
        child: Icon(
          Icons.apartment_rounded,
          size: 80,
          color: AppColors.primary.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final p = controller.property.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            // Sliver App Bar with Image
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              backgroundColor: AppColors.primary,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textPrimary),
                ),
                onPressed: () => Get.back(),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      controller.isFavorite.value ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: controller.isFavorite.value ? Colors.red : AppColors.textSecondary,
                    ),
                  ),
                  onPressed: controller.toggleFavorite,
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: AppColors.primarySoft,
                      child: _buildPropertyDetailImage(p.mainImage),
                    ),
                    // Gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (p.isVerified)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'verified_property'.tr,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Content body
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name ?? "Property Details",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      p.fullLocation,
                                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (p.averageRating != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accentOrangeLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: AppColors.accentOrange, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  p.averageRating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accentOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Price Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('starting_from'.tr, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text(
                                "\$${(p.minRoomPrice ?? 0).toStringAsFixed(0)} / month",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${p.availableRoomCount ?? 0} ${'available_rooms_count'.tr}",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Description
                    Text('description'.tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      p.description ?? "No description available for this property.",
                      style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                    ),

                    const SizedBox(height: 20),

                    // Facilities
                    Text('facilities'.tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        FacilityChip(name: "WIFI"),
                        FacilityChip(name: "AIR_CONDITIONER"),
                        FacilityChip(name: "PRIVATE_BATHROOM"),
                        FacilityChip(name: "PARKING"),
                        FacilityChip(name: "SECURITY"),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Owner Card
                    Text('owner_information'.tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primarySoft,
                            child: Text(
                              (p.owner?.displayName ?? "O")[0].toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.owner?.displayName ?? "Property Owner",
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.owner?.phoneNumber ?? "098765432",
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Get.snackbar("Contact", "Call owner at: ${p.owner?.phoneNumber ?? '098765432'}");
                            },
                            icon: const Icon(Icons.phone, size: 16),
                            label: Text('call_owner'.tr),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Available Rooms Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('available_rooms_in_building'.tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        Obx(() => Text("${controller.rooms.length} ${'rooms'.tr}", style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Obx(() {
                      if (controller.rooms.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Center(
                            child: Text('no_available_rooms'.tr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.rooms.length,
                        itemBuilder: (ctx, i) {
                          final room = controller.rooms[i];
                          return RoomCard(
                            room: room,
                            onTap: () => Get.toNamed(AppRouteName.roomDetail, arguments: room),
                          );
                        },
                      );
                    }),

                    const SizedBox(height: 24),

                    // Reviews Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('reviews_section'.tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () => _showReviewDialog(context),
                          child: Text('write_review'.tr, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Obx(() {
                      if (controller.reviews.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Center(
                            child: Text('be_first_to_review'.tr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.reviews.length,
                        itemBuilder: (ctx, i) {
                          final rev = controller.reviews[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      rev.studentName ?? "Student",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Row(
                                      children: List.generate(
                                        5,
                                        (starIndex) => Icon(
                                          Icons.star_rounded,
                                          size: 14,
                                          color: starIndex < (rev.rating ?? 5) ? AppColors.accentOrange : AppColors.border,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (rev.comment != null) ...[
                                  const SizedBox(height: 6),
                                  Text(rev.comment!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    }),

                    const SizedBox(height: 90), // Bottom padding for sticky bar
                  ],
                ),
              ),
            ),
          ],
        ),

        // Sticky Bottom CTA Bar
        bottomSheet: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => RequestVisitDialog(
                          propertyId: p.id ?? 1,
                          propertyName: p.name ?? "Property",
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'book_visit'.tr,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _showReviewDialog(BuildContext context) {
    int rating = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('write_review'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      Icons.star_rounded,
                      size: 32,
                      color: index < rating ? AppColors.accentOrange : AppColors.border,
                    ),
                    onPressed: () => setState(() => rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: LanguageService.isKhmer ? "មតិយោបល់របស់អ្នកអំពីបន្ទប់នេះ..." : "Your review about this property...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await controller.submitReview(rating, commentCtrl.text.trim());
                if (success) Get.back();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: Text('post'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
