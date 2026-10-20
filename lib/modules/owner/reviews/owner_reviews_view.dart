import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/language_service.dart';
import '../../../widgets/animated_widgets.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/custom_app_bar.dart';
import 'owner_reviews_controller.dart';

class OwnerReviewsView extends StatelessWidget {
  const OwnerReviewsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OwnerReviewsController());

    return Obx(() {
      LanguageService.currentLocale.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: 'reviews'.tr,
          showBack: true,
          showProperty: false,
          showLanguage: false,
          isOwner: true,
        ),
        body: RefreshIndicator(
          onRefresh: controller.loadReviews,
          color: AppColors.primary,
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall Rating Summary Card
                  _buildRatingOverviewCard(context, controller),

                  const SizedBox(height: 20),

                  // Reviews List Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        LanguageService.isKhmer ? "មតិយោបល់ទាំងអស់" : "All Reviews",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${controller.totalReviews} ${LanguageService.isKhmer ? 'មតិ' : 'reviews'}",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Reviews List or Empty State
                  if (controller.reviews.isEmpty)
                    _buildEmptyState()
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.reviews.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final rev = controller.reviews[i];
                        return _buildReviewItem(rev);
                      },
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          }),
        ),
      );
    });
  }

  Widget _buildRatingOverviewCard(BuildContext context, OwnerReviewsController controller) {
    final avg = controller.averageRating;
    final total = controller.totalReviews;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Big Rating Number & Stars
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedCountText(
                  value: avg,
                  decimalPlaces: 1,
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (starIdx) {
                    final isFilled = starIdx < avg.round();
                    return Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: isFilled ? Colors.amber : Colors.grey.shade300,
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Text(
                  "$total ${LanguageService.isKhmer ? 'ការវាយតម្លៃ' : 'ratings'}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 1,
            height: 90,
            color: AppColors.border,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // Right: Star distribution bars
          Expanded(
            flex: 6,
            child: Column(
              children: List.generate(5, (index) {
                final starNum = 5 - index;
                final percentage = controller.percentageForStar(starNum);
                final count = controller.countForStar(starNum);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        "$starNum",
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AnimatedProgressBar(
                          value: percentage,
                          height: 6,
                          backgroundColor: AppColors.background,
                          foregroundColor: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 20,
                        child: Text(
                          "$count",
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(dynamic rev) {
    final rating = rev.rating ?? 5;
    final name = (rev.studentName != null && rev.studentName.toString().isNotEmpty)
        ? rev.studentName.toString()
        : "Student";
    final comment = rev.comment ?? "";
    final dateStr = rev.createdAt?.toString() ?? "";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : "S",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (dateStr.isNotEmpty)
                      Text(
                        dateStr.length > 10 ? dateStr.substring(0, 10) : dateStr,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (starIndex) => Icon(
                    Icons.star_rounded,
                    size: 15,
                    color: starIndex < rating ? Colors.amber : Colors.grey.shade300,
                  ),
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comment,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.star_outline_rounded, size: 40, color: Colors.amber.shade700),
          ),
          const SizedBox(height: 16),
          Text(
            'no_reviews_yet'.tr,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            LanguageService.isKhmer
                ? "នៅពេលដែលអ្នកជួល ឬសិស្សវាយតម្លៃបន្ទប់ជួលរបស់អ្នក វានឹងបង្ហាញនៅទីនេះ។"
                : "When tenants or students review your property, their ratings will appear here.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
