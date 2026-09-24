import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/constant_uri.dart';
import '../../../core/services/api_service.dart';
import '../../../models/rental/favorite_model.dart';
import '../home/student_home_controller.dart';

class FavoritesController extends GetxController {
  final ApiService apiService;
  FavoritesController({required this.apiService});

  final favorites = <FavoriteModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    isLoading.value = true;
    try {
      final res = await apiService.getApi(ConstantUri.favorites);
      if (res != null) {
        final decoded = jsonDecode(res);
        final data = decoded['data'];
        List items = [];
        if (data != null) {
          if (data is Map && data['content'] is List) {
            items = data['content'];
          } else if (data is List) {
            items = data;
          }
        }
        favorites.assignAll(items.map((e) => FavoriteModel.fromJson(e)).toList());
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeFavorite(int? id, {int? propertyId}) async {
    final item = favorites.firstWhereOrNull((f) => (id != null && f.id == id) || (propertyId != null && f.property?.id == propertyId));
    final propId = propertyId ?? item?.property?.id;
    final favId = id ?? item?.id;

    favorites.removeWhere((f) => (favId != null && f.id == favId) || (propId != null && f.property?.id == propId));
    Get.snackbar("Favorite", "Removed from favorites", backgroundColor: Colors.white, duration: const Duration(seconds: 1));

    if (propId != null && Get.isRegistered<StudentHomeController>()) {
      final homeCtrl = Get.find<StudentHomeController>();
      homeCtrl.favoriteIds.remove(propId);
      homeCtrl.propertyFavoriteMap.remove(propId);
    }

    try {
      if (favId != null) {
        await apiService.deleteApi(ConstantUri.deleteFavorite(favId));
      } else if (propId != null) {
        await apiService.deleteApi(ConstantUri.deleteFavoriteByProperty(propId));
      }
    } catch (_) {
      if (propId != null) {
        try {
          await apiService.deleteApi(ConstantUri.deleteFavoriteByProperty(propId));
        } catch (_) {}
      }
    }
  }
}
