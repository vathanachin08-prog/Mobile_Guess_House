import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/constant_uri.dart';
import '../../../core/services/api_service.dart';
import '../../../models/rental/review_model.dart';
import '../owner_main_controller.dart';

class OwnerReviewsController extends GetxController {
  final ApiService? apiService;
  OwnerReviewsController({this.apiService});

  final isLoading = false.obs;
  final reviews = <ReviewModel>[].obs;
  final selectedPropertyId = RxnInt();
  final selectedPropertyName = "".obs;

  double get averageRating {
    if (reviews.isEmpty) return 0.0;
    final total = reviews.fold<num>(0, (sum, item) => sum + (item.rating ?? 5));
    return total / reviews.length;
  }

  int get totalReviews => reviews.length;

  int countForStar(int star) {
    return reviews.where((r) => (r.rating ?? 5) == star).length;
  }

  double percentageForStar(int star) {
    if (reviews.isEmpty) return 0.0;
    return countForStar(star) / reviews.length;
  }

  @override
  void onInit() {
    super.onInit();
    final ownerMain = Get.isRegistered<OwnerMainController>()
        ? Get.find<OwnerMainController>()
        : null;
    if (ownerMain != null && ownerMain.selectedPropertyId.value != null) {
      selectedPropertyId.value = ownerMain.selectedPropertyId.value;
      selectedPropertyName.value = ownerMain.selectedPropertyName.value;
    }
    loadReviews();
  }

  Future<void> loadReviews() async {
    final pId = selectedPropertyId.value;
    if (pId == null) {
      reviews.clear();
      return;
    }

    isLoading.value = true;
    try {
      final api = apiService ?? (Get.isRegistered<ApiService>() ? Get.find<ApiService>() : null);
      if (api != null) {
        final res = await api.getApi(ConstantUri.publicReviews(pId));
        if (res != null) {
          final decoded = res is Map ? res : jsonDecode(res.toString());
          final data = decoded['data'];
          if (data is List) {
            reviews.assignAll(data.map((e) => ReviewModel.fromJson(e)).toList());
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading reviews for property $pId: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void switchProperty(int id, String name) {
    selectedPropertyId.value = id;
    selectedPropertyName.value = name;
    loadReviews();
  }
}
