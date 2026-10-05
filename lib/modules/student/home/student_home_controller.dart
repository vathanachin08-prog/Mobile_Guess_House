import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/constant_uri.dart';
import '../../../core/services/api_service.dart';
import '../../../models/rental/property_model.dart';
import '../../../models/rental/favorite_model.dart';
import '../../../widgets/app_colors.dart';
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
  final notificationsList = <Map<String, dynamic>>[].obs;
  final unreadNotificationsCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadProperties();
    loadFavorites();
    loadNotifications();
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
        } else {
          properties.clear();
        }
      }
    } catch (e) {
      debugPrint("Error loading public properties: $e");
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

  Future<void> loadNotifications() async {
    final List<Map<String, dynamic>> items = [
      {
        "id": "student_welcome",
        "title": "សូមស្វាគមន៍មកកាន់ RoomFinder KH",
        "message": "ស្វែងរកបន្ទប់ជួល និងផ្ទះជួលដែលមានសុវត្ថិភាព តម្លៃសមរម្យ និងនៅជិតសាកលវិទ្យាល័យរបស់អ្នក!",
        "time": "ទើបតែឥឡូវ",
        "icon": Icons.celebration_rounded,
        "color": AppColors.primary,
        "isUnread": false,
      },
    ];

    try {
      final res = await apiService.getApi(ConstantUri.myVisitRequests);
      if (res != null) {
        final decoded = res is Map ? res : jsonDecode(res.toString());
        final data = decoded['data'];
        List reqList = [];
        if (data != null) {
          if (data is Map && data['content'] is List) {
            reqList = data['content'];
          } else if (data is List) {
            reqList = data;
          }
        }

        for (var r in reqList) {
          final id = r['id'];
          final status = (r['status'] ?? '').toString().toUpperCase();
          final propName = r['propertyName'] ?? 'អគារស្នាក់នៅ';
          final date = r['requestedDate'] ?? '';
          final time = r['requestedTime'] ?? '';

          if (status == 'ACCEPTED') {
            items.insert(0, {
              "id": "student_visit_$id",
              "title": "ការណាត់ជួបត្រូវបានយល់ព្រម! ($propName)",
              "message": "ម្ចាស់ផ្ទះបានយល់ព្រមទទួលការណាត់ជួបរបស់អ្នកនៅថ្ងៃ $date ម៉ោង $time។ សូមត្រៀមខ្លួនទៅទស្សនា!",
              "time": "បានយល់ព្រម",
              "icon": Icons.check_circle_rounded,
              "color": AppColors.success,
              "isUnread": true,
              "tabIndex": 3,
            });
          } else if (status == 'REJECTED') {
            items.insert(0, {
              "id": "student_visit_$id",
              "title": "ការណាត់ជួបត្រូវបានបដិសេធ ($propName)",
              "message": "ការស្នើសុំណាត់ជួបរបស់អ្នកនៅថ្ងៃ $date ត្រូវបានបដិសេធ។ សូមជ្រើសរើសពេលវេលាផ្សេង។",
              "time": "បានបដិសេធ",
              "icon": Icons.cancel_rounded,
              "color": AppColors.danger,
              "isUnread": true,
              "tabIndex": 3,
            });
          } else if (status == 'PENDING') {
            items.insert(0, {
              "id": "student_visit_$id",
              "title": "កំពុងរង់ចាំការឆ្លើយតប ($propName)",
              "message": "ការស្នើសុំណាត់ជួបរបស់អ្នកនៅថ្ងៃ $date ម៉ោង $time កំពុងរង់ចាំការឆ្លើយតបពីម្ចាស់ផ្ទះ។",
              "time": "កំពុងរង់ចាំ",
              "icon": Icons.pending_actions_rounded,
              "color": AppColors.accentOrange,
              "isUnread": false,
              "tabIndex": 3,
            });
          }
        }
      }
    } catch (_) {}

    notificationsList.assignAll(items);
    unreadNotificationsCount.value = items.where((n) => n['isUnread'] == true).length;
  }

  void markAllNotificationsAsRead() {
    unreadNotificationsCount.value = 0;
    for (var n in notificationsList) {
      n['isUnread'] = false;
    }
    notificationsList.refresh();
  }

  void markNotificationAsRead(String id) {
    final idx = notificationsList.indexWhere((n) => n['id'] == id);
    if (idx != -1) {
      notificationsList[idx]['isUnread'] = false;
      notificationsList.refresh();
      unreadNotificationsCount.value = notificationsList.where((n) => n['isUnread'] == true).length;
    }
  }
}
