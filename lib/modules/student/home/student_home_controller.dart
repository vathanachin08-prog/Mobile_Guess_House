import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/constant_uri.dart';
import '../../../core/services/api_service.dart';
import '../../../models/rental/property_model.dart';
import '../../../models/rental/room_model.dart';
import '../../../models/rental/facility_model.dart';

class StudentHomeController extends GetxController {
  final ApiService apiService;
  StudentHomeController({required this.apiService});

  final properties = <PropertyModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final selectedCategory = "ALL".obs;
  final favoriteIds = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadProperties();
  }

  List<PropertyModel> get filteredProperties {
    if (selectedCategory.value == "ALL") return properties;
    return properties.where((p) => (p.propertyType ?? '').toUpperCase() == selectedCategory.value).toList();
  }

  List<PropertyModel> get verifiedProperties {
    return properties.where((p) => p.isVerified).toList();
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
      // If server returned 0 properties (fresh DB), provide demo properties matching E-Home KH reference
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
    if (favoriteIds.contains(p.id)) {
      favoriteIds.remove(p.id);
      Get.snackbar("Favorite", "Removed from favorites", duration: const Duration(seconds: 1));
    } else {
      favoriteIds.add(p.id!);
      Get.snackbar("Favorite", "Added to favorites", duration: const Duration(seconds: 1), backgroundColor: Colors.green.shade50);
      try {
        await apiService.postApi(ConstantUri.favorites, body: {"propertyId": p.id});
      } catch (_) {}
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
