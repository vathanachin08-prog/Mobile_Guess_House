import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/constant_uri.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../models/rental/property_model.dart';
import '../../../models/rental/room_model.dart';
import '../../../models/rental/review_model.dart';
import '../../../models/rental/favorite_model.dart';
import '../home/student_home_controller.dart';
import '../favorites/favorites_controller.dart';

class PropertyDetailController extends GetxController {
  final ApiService apiService;
  PropertyDetailController({required this.apiService});

  late Rx<PropertyModel> property;
  final rooms = <RoomModel>[].obs;
  final reviews = <ReviewModel>[].obs;
  final isLoading = false.obs;
  final isFavorite = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is PropertyModel) {
      property = args.obs;
      if (args.rooms != null && args.rooms!.isNotEmpty) {
        rooms.assignAll(args.rooms!);
      }
      loadDetails(args.id);
    } else if (args is int) {
      property = PropertyModel(id: args).obs;
      loadDetails(args);
    }
    _syncInitialFavorite();
  }

  void _syncInitialFavorite() {
    final targetId = property.value.id;
    if (targetId != null && Get.isRegistered<StudentHomeController>()) {
      isFavorite.value = Get.find<StudentHomeController>().favoriteIds.contains(targetId);
    }
  }

  Future<void> loadDetails(int? id) async {
    if (id == null) return;
    isLoading.value = true;
    try {
      // 1. Fetch Property Details
      final res = await apiService.getApi(ConstantUri.publicPropertyDetail(id));
      if (res != null) {
        final decoded = jsonDecode(res);
        if (decoded['data'] != null) {
          final p = PropertyModel.fromJson(decoded['data']);
          property.value = p;
          if (p.rooms != null && p.rooms!.isNotEmpty) {
            rooms.assignAll(p.rooms!);
          }
          _syncInitialFavorite();
        }
      }

      // 2. Fetch Reviews
      final revRes = await apiService.getApi(ConstantUri.publicReviews(id));
      if (revRes != null) {
        final revDecoded = jsonDecode(revRes);
        if (revDecoded['data'] != null && revDecoded['data'] is List) {
          final List list = revDecoded['data'];
          reviews.assignAll(list.map((e) => ReviewModel.fromJson(e)).toList());
        }
      }
    } catch (_) {
      // Keep existing arguments
    } finally {
      isLoading.value = false;
    }
  }

  void toggleFavorite() async {
    final pId = property.value.id;
    if (pId == null) return;

    StudentHomeController? homeCtrl;
    if (Get.isRegistered<StudentHomeController>()) {
      homeCtrl = Get.find<StudentHomeController>();
    }

    if (isFavorite.value) {
      // Un-favorite
      isFavorite.value = false;
      final favId = homeCtrl?.propertyFavoriteMap[pId];
      homeCtrl?.favoriteIds.remove(pId);
      homeCtrl?.propertyFavoriteMap.remove(pId);

      if (Get.isRegistered<FavoritesController>()) {
        Get.find<FavoritesController>().favorites.removeWhere((f) => f.property?.id == pId);
      }

      Get.snackbar("Favorite", "Removed from favorites", backgroundColor: Colors.white, duration: const Duration(seconds: 1));

      try {
        if (favId != null) {
          await apiService.deleteApi(ConstantUri.deleteFavorite(favId));
        } else {
          await apiService.deleteApi(ConstantUri.deleteFavoriteByProperty(pId));
        }
      } catch (_) {
        try {
          await apiService.deleteApi(ConstantUri.deleteFavoriteByProperty(pId));
        } catch (_) {}
      }
    } else {
      // Add favorite
      isFavorite.value = true;
      homeCtrl?.favoriteIds.add(pId);

      if (Get.isRegistered<FavoritesController>()) {
        final favCtrl = Get.find<FavoritesController>();
        if (!favCtrl.favorites.any((f) => f.property?.id == pId)) {
          favCtrl.favorites.insert(0, FavoriteModel(
            property: property.value,
            createdAt: DateTime.now().toIso8601String(),
          ));
        }
      }

      Get.snackbar("Favorite", "Saved to favorites", backgroundColor: Colors.green.shade50, duration: const Duration(seconds: 1));

      try {
        final res = await apiService.postApi(ConstantUri.favorites, body: {"propertyId": pId});
        if (res != null) {
          final decoded = jsonDecode(res);
          if (decoded['data'] != null && decoded['data']['id'] != null) {
            final int favId = decoded['data']['id'];
            homeCtrl?.propertyFavoriteMap[pId] = favId;
          }
        }
        if (Get.isRegistered<FavoritesController>()) {
          Get.find<FavoritesController>().loadFavorites();
        }
      } catch (_) {
        isFavorite.value = true;
        homeCtrl?.favoriteIds.add(pId);
      }
    }
  }

  Future<bool> submitReview(int rating, String comment) async {
    final pId = property.value.id;
    if (pId == null) return false;
    try {
      final res = await apiService.postApi(
        ConstantUri.propertyReviews(pId),
        body: {"rating": rating, "comment": comment},
      );
      if (res != null) {
        AppFirebaseService.logReviewForm(
          propertyId: pId,
          rating: rating,
          success: true,
        );
        Get.snackbar("Success", "Review submitted! Thank you.", backgroundColor: Colors.green.shade50);
        reviews.insert(0, ReviewModel(
          studentName: "You",
          rating: rating,
          comment: comment,
          createdAt: DateTime.now().toIso8601String(),
        ));
        return true;
      } else {
        AppFirebaseService.logReviewForm(
          propertyId: pId,
          rating: rating,
          success: false,
          errorMessage: "API returned null",
        );
      }
    } catch (e) {
      AppFirebaseService.logReviewForm(
        propertyId: pId,
        rating: rating,
        success: false,
        errorMessage: e.toString(),
      );
      Get.snackbar("Error", "Could not submit review: $e");
    }
    return false;
  }
}
