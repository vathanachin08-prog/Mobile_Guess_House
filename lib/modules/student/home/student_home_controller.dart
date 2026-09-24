import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/constant_uri.dart';
import '../../../core/services/api_service.dart';
import '../../../models/rental/property_model.dart';
import '../../../models/rental/room_model.dart';
import '../../../models/rental/facility_model.dart';
import '../../../models/rental/favorite_model.dart';
import '../favorites/favorites_controller.dart';

class StudentHomeController extends GetxController {
  final ApiService apiService;
  StudentHomeController({required this.apiService});

  final properties = <PropertyModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final selectedCategory = "ALL".obs;
  final favoriteIds = <int>{}.obs;
  final propertyFavoriteMap = <int, int>{}.obs; // propertyId -> favoriteId

  @override
  void onInit() {
    super.onInit();
    loadProperties();
    loadFavorites();
  }

  List<PropertyModel> get filteredProperties {
    if (selectedCategory.value == "ALL") return properties;
    return properties.where((p) => (p.propertyType ?? '').toUpperCase() == selectedCategory.value).toList();
  }

  List<PropertyModel> get verifiedProperties {
    return properties.where((p) => p.isVerified).toList();
  }

  Future<void> loadFavorites() async {
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
        for (var item in items) {
          final favId = item['id'];
          final prop = item['property'];
          if (prop != null && prop['id'] != null) {
            final propId = prop['id'] as int;
            favoriteIds.add(propId);
            if (favId != null) {
              propertyFavoriteMap[propId] = favId as int;
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> loadProperties() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final res = await apiService.getApi(ConstantUri.publicProperties);
      if (res != null) {
        final decoded = jsonDecode(res);
        if (decoded['data'] != null && decoded['data']['content'] != null) {
          final List content = decoded['data']['content'];
          final list = content.map((e) => PropertyModel.fromJson(e)).toList();
          properties.assignAll(list);
        }
      }
      // If server returned 0 properties (fresh DB), provide demo properties matching RoomFinder KH reference
      if (properties.isEmpty) {
        properties.assignAll(_getDemoProperties());
      }
    } catch (e) {
      // Fallback demo properties for offline or connection issues
      if (properties.isEmpty) {
        properties.assignAll(_getDemoProperties());
      }
    } finally {
      isLoading.value = false;
    }
  }

  void setCategory(String cat) {
    selectedCategory.value = cat;
  }

  void toggleFavorite(PropertyModel p) async {
    if (p.id == null) return;
    final propId = p.id!;

    if (favoriteIds.contains(propId)) {
      // 1. Un-favorite
      final favId = propertyFavoriteMap[propId];
      favoriteIds.remove(propId);
      propertyFavoriteMap.remove(propId);
      Get.snackbar("Favorite", "Removed from favorites", duration: const Duration(seconds: 1), backgroundColor: Colors.white);

      if (Get.isRegistered<FavoritesController>()) {
        Get.find<FavoritesController>().favorites.removeWhere((f) => f.property?.id == propId);
      }

      try {
        if (favId != null) {
          await apiService.deleteApi(ConstantUri.deleteFavorite(favId));
        } else {
          await apiService.deleteApi(ConstantUri.deleteFavoriteByProperty(propId));
        }
      } catch (_) {
        try {
          await apiService.deleteApi(ConstantUri.deleteFavoriteByProperty(propId));
        } catch (_) {}
      }
    } else {
      // 2. Add favorite
      favoriteIds.add(propId);
      Get.snackbar("Favorite", "Added to favorites", duration: const Duration(seconds: 1), backgroundColor: Colors.green.shade50);

      if (Get.isRegistered<FavoritesController>()) {
        final favCtrl = Get.find<FavoritesController>();
        if (!favCtrl.favorites.any((f) => f.property?.id == propId)) {
          favCtrl.favorites.insert(0, FavoriteModel(
            property: p,
            createdAt: DateTime.now().toIso8601String(),
          ));
        }
      }

      try {
        final res = await apiService.postApi(ConstantUri.favorites, body: {"propertyId": propId});
        if (res != null) {
          final decoded = jsonDecode(res);
          if (decoded['data'] != null && decoded['data']['id'] != null) {
            propertyFavoriteMap[propId] = decoded['data']['id'];
          }
        }
        if (Get.isRegistered<FavoritesController>()) {
          Get.find<FavoritesController>().loadFavorites();
        }
      } catch (_) {
        favoriteIds.add(propId);
      }
    }
  }

  List<PropertyModel> _getDemoProperties() {
    return [
      PropertyModel(
        id: 1,
        name: "Sunrise Student Dormitory",
        description: "Modern, quiet, and secure rental rooms within 5 minutes walk from RUPP and IFL. Free WiFi and parking included.",
        propertyType: "DORMITORY",
        address: "Russian Federation Blvd",
        district: "Tuol Kouk",
        city: "Phnom Penh",
        latitude: 11.5683,
        longitude: 104.8902,
        status: "PUBLISHED",
        verificationStatus: "VERIFIED",
        minRoomPrice: 65.0,
        availableRoomCount: 3,
        totalRoomCount: 8,
        averageRating: 4.8,
        reviewCount: 12,
        owner: OwnerSummaryModel(
          id: 3,
          firstName: "Owner",
          lastName: "Sokha",
          phoneNumber: "098765432",
        ),
        rooms: [
          RoomModel(
            id: 101,
            roomNumber: "A101",
            title: "Single Room with Private Bathroom",
            price: 65.0,
            floor: 1,
            area: 18.0,
            roomType: "SINGLE",
            genderPreference: "ANY",
            available: true,
            facilities: [
              FacilityModel(name: "WIFI"),
              FacilityModel(name: "AIR_CONDITIONER"),
              FacilityModel(name: "PRIVATE_BATHROOM"),
            ],
          ),
          RoomModel(
            id: 102,
            roomNumber: "B201",
            title: "Double Room with Balcony",
            price: 90.0,
            floor: 2,
            area: 25.0,
            roomType: "DOUBLE",
            genderPreference: "ANY",
            available: true,
            facilities: [
              FacilityModel(name: "WIFI"),
              FacilityModel(name: "AIR_CONDITIONER"),
              FacilityModel(name: "PRIVATE_BATHROOM"),
              FacilityModel(name: "FURNITURE"),
            ],
          ),
        ],
      ),
      PropertyModel(
        id: 2,
        name: "Campus View Apartment",
        description: "Spacious private student apartments near Norton University with full air conditioning, study desk, and 24/7 security guard.",
        propertyType: "APARTMENT",
        address: "St. 337, Boeung Kak 1",
        district: "Tuol Kouk",
        city: "Phnom Penh",
        latitude: 11.5790,
        longitude: 104.9010,
        status: "PUBLISHED",
        verificationStatus: "VERIFIED",
        minRoomPrice: 85.0,
        availableRoomCount: 2,
        totalRoomCount: 6,
        averageRating: 4.6,
        reviewCount: 8,
        owner: OwnerSummaryModel(
          id: 4,
          firstName: "Veasna",
          lastName: "Chea",
          phoneNumber: "0889495446",
        ),
        rooms: [
          RoomModel(
            id: 201,
            roomNumber: "C301",
            title: "Studio Room with Kitchen",
            price: 85.0,
            floor: 3,
            area: 22.0,
            roomType: "SINGLE",
            genderPreference: "ANY",
            available: true,
            facilities: [
              FacilityModel(name: "WIFI"),
              FacilityModel(name: "AIR_CONDITIONER"),
              FacilityModel(name: "KITCHEN"),
              FacilityModel(name: "SECURITY"),
            ],
          ),
        ],
      ),
      PropertyModel(
        id: 3,
        name: "Green Garden Residence",
        description: "Affordable and friendly rooms for university students. Includes shared kitchen and high-speed fiber WiFi.",
        propertyType: "ROOM",
        address: "St. 271, Teuk Thla",
        district: "Sen Sok",
        city: "Phnom Penh",
        latitude: 11.5540,
        longitude: 104.8820,
        status: "PUBLISHED",
        verificationStatus: "PENDING",
        minRoomPrice: 50.0,
        availableRoomCount: 4,
        totalRoomCount: 10,
        averageRating: 4.4,
        reviewCount: 5,
        owner: OwnerSummaryModel(
          id: 5,
          firstName: "Dara",
          lastName: "Meng",
          phoneNumber: "012889900",
        ),
      ),
    ];
  }
}
