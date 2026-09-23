import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/constant_uri.dart';
import '../../../core/services/api_service.dart';
import '../../../models/rental/favorite_model.dart';

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
        if (decoded['data'] != null && decoded['data'] is List) {
          final List list = decoded['data'];
          favorites.assignAll(list.map((e) => FavoriteModel.fromJson(e)).toList());
        }
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeFavorite(int? id) async {
    if (id == null) return;
    favorites.removeWhere((f) => f.id == id);
    Get.snackbar("Favorite", "Removed from favorites", backgroundColor: Colors.white, duration: const Duration(seconds: 1));
    try {
      await apiService.deleteApi(ConstantUri.deleteFavorite(id));
    } catch (_) {}
  }
}
