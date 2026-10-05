import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/language_service.dart';
import '../../../routes/app_route_name.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/property_card.dart';
import '../../../widgets/room_card.dart';
import 'favorites_controller.dart';

class FavoritesView extends GetView<FavoritesController> {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      LanguageService.currentLocale.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: 'saved_favorites'.tr,
          subtitle: 'my_activity'.tr,
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (controller.favorites.isEmpty) {
            return EmptyStateWidget(
              title: 'no_favorites_yet'.tr,
              message: 'save_favorites_hint'.tr,
              icon: Icons.favorite_border_rounded,
            );
          }

          return RefreshIndicator(
            onRefresh: controller.loadFavorites,
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.favorites.length,
              itemBuilder: (ctx, i) {
                final fav = controller.favorites[i];
                if (fav.property != null) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: PropertyCard(
                      property: fav.property!,
                      isFavorite: true,
                      onFavoriteTap: () => controller.removeFavorite(fav.id, propertyId: fav.property?.id),
                      onTap: () => Get.toNamed(AppRouteName.propertyDetail, arguments: fav.property),
                    ),
                  );
                } else if (fav.room != null) {
                  return RoomCard(
                    room: fav.room!,
                    onTap: () => Get.toNamed(AppRouteName.roomDetail, arguments: fav.room),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          );
        }),
      );
    });
  }
}
