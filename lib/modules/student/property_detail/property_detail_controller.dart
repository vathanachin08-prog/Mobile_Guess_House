import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/constant_uri.dart';
import '../../../core/services/api_service.dart';
import '../../../models/rental/property_model.dart';
import '../../../models/rental/room_model.dart';
import '../../../models/rental/review_model.dart';

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
    isFavorite.value = !isFavorite.value;
    if (isFavorite.value) {
      Get.snackbar("Favorite", "Saved to favorites", backgroundColor: Colors.green.shade50);
      try {
        await apiService.postApi(ConstantUri.favorites, body: {"propertyId": pId});
      } catch (_) {}
    } else {
      Get.snackbar("Favorite", "Removed from favorites");
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
        Get.snackbar("Success", "Review submitted! Thank you.", backgroundColor: Colors.green.shade50);
        reviews.insert(0, ReviewModel(
          studentName: "You",
          rating: rating,
          comment: comment,
          createdAt: DateTime.now().toIso8601String(),
        ));
        return true;
      }
    } catch (e) {
      Get.snackbar("Error", "Could not submit review: $e");
    }
    return false;
  }
}
