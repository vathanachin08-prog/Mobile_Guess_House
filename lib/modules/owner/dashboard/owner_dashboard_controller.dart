import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../constants/constant_uri.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/language_service.dart';
import '../../../data/local/token_store_local.dart';
import '../../../models/rental/property_model.dart';
import '../../../models/rental/visit_request_model.dart';
import '../../../widgets/app_colors.dart';
import '../floors/owner_floors_controller.dart';
import '../rooms/owner_rooms_controller.dart';
import '../tenants/owner_tenants_controller.dart';
import '../invoices/owner_invoices_controller.dart';
import '../visit_requests/owner_visit_requests_controller.dart';
import '../owner_main_controller.dart';

class OwnerDashboardController extends GetxController {
  final ApiService apiService;
  OwnerDashboardController({required this.apiService});

  final myProperties = <PropertyModel>[].obs;
  final currentProperty = Rxn<PropertyModel>();
  final isLoading = false.obs;

  // Stats dynamically computed or synced from actual data
  final totalFloors = 0.obs;
  final totalRooms = 0.obs;
  final availableRooms = 0.obs;
  final occupiedRooms = 0.obs;
  final totalTenants = 0.obs;
  final unpaidInvoices = 0.obs;
  final totalRevenue = 0.0.obs;
  final expectedRevenue = 0.0.obs;
  final pendingVisitRequestsCount = 0.obs;
  final latestVisitRequest = Rxn<VisitRequestModel>();

  final user = Rxn<Map<String, dynamic>>();
  final ownerNameRx = "Owner".obs;
  final profileImagePath = "".obs;
  final isBalanceHidden = false.obs;

  void toggleBalanceVisibility() {
    isBalanceHidden.toggle();
  }

  @override
  void onInit() {
    super.onInit();
    _loadUserInfo();
    loadDashboard();
  }

  void _loadUserInfo() {
    final u = TokenStoreLocal.getUser();
    user.value = u;
    if (u != null) {
      final first = u['firstName'] ?? '';
      final last = u['lastName'] ?? '';
      if (first.toString().isNotEmpty || last.toString().isNotEmpty) {
        ownerNameRx.value = "$first $last".trim();
      } else {
        final un = u['username'];
        if (un != null && un.toString().isNotEmpty) {
          ownerNameRx.value = un.toString();
        } else {
          ownerNameRx.value = 'Owner';
        }
      }
    } else {
      ownerNameRx.value = 'Owner';
    }
    loadAvatar();
  }

  void loadAvatar() {
    profileImagePath.value = "";
    final u = TokenStoreLocal.getUser();
    final p = u?['profile']?.toString() ?? '';
    if (p.isNotEmpty) {
      profileImagePath.value = p.startsWith('http') || p.startsWith('data:image')
          ? p
          : "${ConstantUri.baseUri}/api/public/view/image?filename=$p";
      return;
    }

    try {
      final box = GetStorage();
      final key = TokenStoreLocal.getUserScopedKey("OWNER_PROFILE_AVATAR_KEY");
      final serverUrl = box.read("${key}_SERVER_URL");
      if (serverUrl != null && serverUrl.toString().isNotEmpty) {
        profileImagePath.value = serverUrl.toString();
        return;
      }

      final savedAvatar = box.read(key);
      if (savedAvatar != null && savedAvatar.toString().isNotEmpty) {
        profileImagePath.value = savedAvatar.toString();
      }
    } catch (_) {}
  }

  String get ownerName => ownerNameRx.value;

  double get occupancyRate {
    if (totalRooms.value == 0) return 0.0;
    return (occupiedRooms.value / totalRooms.value) * 100;
  }

  Future<void> loadDashboard() async {
    isLoading.value = true;
    try {
      final res = await apiService.getApi(ConstantUri.myProperties);
      if (res != null) {
        final decoded = res is Map ? res : jsonDecode(res.toString());
        List items = [];
        final data = decoded['data'];
        if (data != null) {
          if (data is Map && data['content'] is List) {
            items = data['content'];
          } else if (data is List) {
            items = data;
          }
        }
        if (items.isNotEmpty) {
          final props = items.map((e) {
            final pm = PropertyModel.fromJson(Map<String, dynamic>.from(e));
            if (pm.id != null) {
              try {
                final box = GetStorage();
                final localKey = TokenStoreLocal.getUserScopedKey("PROPERTY_IMG_${pm.id}");
                final savedImg = box.read(localKey)?.toString();
                if (savedImg != null && savedImg.trim().isNotEmpty) {
                  return PropertyModel(
                    id: pm.id,
                    name: pm.name,
                    description: pm.description,
                    propertyType: pm.propertyType,
                    address: pm.address,
                    city: pm.city,
                    district: pm.district,
                    latitude: pm.latitude,
                    longitude: pm.longitude,
                    status: pm.status,
                    verificationStatus: pm.verificationStatus,
                    mainImage: savedImg.trim(),
                    images: pm.images,
                    owner: pm.owner,
                    rooms: pm.rooms,
                    minRoomPrice: pm.minRoomPrice,
                    availableRoomCount: pm.availableRoomCount,
                    totalRoomCount: pm.totalRoomCount,
                    averageRating: pm.averageRating,
                    reviewCount: pm.reviewCount,
                    createdAt: pm.createdAt,
                    updatedAt: pm.updatedAt,
                  );
                }
              } catch (_) {}
            }
            return pm;
          }).toList();
          myProperties.assignAll(props);
          if (myProperties.isNotEmpty) {
            int? activeId;
            if (Get.isRegistered<OwnerMainController>()) {
              activeId = Get.find<OwnerMainController>().selectedPropertyId.value;
            }
            final match = myProperties.firstWhereOrNull((p) => p.id == activeId);
            final selected = match ?? myProperties.first;
            await switchProperty(selected);
          }
        }
      }
    } catch (_) {
    } finally {
      _syncDynamicStats();
      isLoading.value = false;
    }
  }

  /// Sync stats from registered sub-controllers so dashboard is always 100% dynamic
  void _syncDynamicStats() {
    if (Get.isRegistered<OwnerFloorsController>()) {
      final fCtrl = Get.find<OwnerFloorsController>();
      if (fCtrl.activePropertyId == currentProperty.value?.id) {
        totalFloors.value = fCtrl.floors.length;
      }
    }
    if (Get.isRegistered<OwnerRoomsController>()) {
      final rCtrl = Get.find<OwnerRoomsController>();
      if (rCtrl.activePropertyId == currentProperty.value?.id) {
        totalRooms.value = rCtrl.rooms.length;
        availableRooms.value = rCtrl.rooms.where((r) => r.available == true).length;
        occupiedRooms.value = rCtrl.rooms.where((r) => r.available == false).length;
      }
    }
    if (Get.isRegistered<OwnerTenantsController>()) {
      final tCtrl = Get.find<OwnerTenantsController>();
      if (tCtrl.activePropertyId == currentProperty.value?.id) {
        totalTenants.value = tCtrl.tenants.length;
      }
    }
    if (Get.isRegistered<OwnerInvoicesController>()) {
      final iCtrl = Get.find<OwnerInvoicesController>();
      if (iCtrl.activePropertyId == currentProperty.value?.id) {
        unpaidInvoices.value = iCtrl.unpaidCount;
        totalRevenue.value = iCtrl.totalCollectedRevenue;
        expectedRevenue.value = iCtrl.totalExpectedRevenue;
      }
    }
  }

  Future<void> switchProperty(PropertyModel p) async {
    // Check if there is a local photo override for this property
    PropertyModel effectiveProp = p;
    if (p.id != null) {
      try {
        final box = GetStorage();
        final localKey = TokenStoreLocal.getUserScopedKey("PROPERTY_IMG_${p.id}");
        final localImg = box.read(localKey)?.toString();
        if (localImg != null && localImg.trim().isNotEmpty) {
          effectiveProp = PropertyModel(
            id: p.id,
            name: p.name,
            description: p.description,
            propertyType: p.propertyType,
            address: p.address,
            city: p.city,
            district: p.district,
            latitude: p.latitude,
            longitude: p.longitude,
            status: p.status,
            verificationStatus: p.verificationStatus,
            mainImage: localImg.trim(),
            images: p.images,
            owner: p.owner,
            rooms: p.rooms,
            minRoomPrice: p.minRoomPrice,
            availableRoomCount: p.availableRoomCount,
            totalRoomCount: p.totalRoomCount,
            averageRating: p.averageRating,
            reviewCount: p.reviewCount,
            createdAt: p.createdAt,
            updatedAt: p.updatedAt,
          );
        }
      } catch (_) {}
    }
    currentProperty.value = effectiveProp;
    if (p.totalRoomCount != null) {
      totalRooms.value = p.totalRoomCount!;
      availableRooms.value = p.availableRoomCount ?? 0;
      occupiedRooms.value = (p.totalRoomCount! - (p.availableRoomCount ?? 0)).clamp(0, p.totalRoomCount!);
    } else if (p.rooms != null) {
      final rList = p.rooms!;
      totalRooms.value = rList.length;
      availableRooms.value = rList.where((r) => r.available == true).length;
      occupiedRooms.value = rList.where((r) => r.available == false).length;
    } else {
      totalRooms.value = 0;
      availableRooms.value = 0;
      occupiedRooms.value = 0;
    }

    // Immediately reset counts so we don't display stale data from another property
    totalFloors.value = 0;
    if (Get.isRegistered<OwnerFloorsController>()) {
      final fCtrl = Get.find<OwnerFloorsController>();
      if (fCtrl.activePropertyId == p.id) {
        totalFloors.value = fCtrl.floors.length;
      }
    }

    totalTenants.value = 0;
    if (Get.isRegistered<OwnerTenantsController>()) {
      final tCtrl = Get.find<OwnerTenantsController>();
      if (tCtrl.activePropertyId == p.id) {
        totalTenants.value = tCtrl.tenants.length;
      }
    }

    if (Get.isRegistered<OwnerInvoicesController>()) {
      final iCtrl = Get.find<OwnerInvoicesController>();
      if (iCtrl.activePropertyId == p.id) {
        unpaidInvoices.value = iCtrl.unpaidCount;
        totalRevenue.value = iCtrl.totalCollectedRevenue;
        expectedRevenue.value = iCtrl.totalExpectedRevenue;
      } else {
        unpaidInvoices.value = 0;
        totalRevenue.value = 0;
        expectedRevenue.value = 0;
      }
    }

    if (p.id != null) {
      await fetchFloorsForProperty(p.id!);
    }

    await fetchVisitRequestsStats();
  }

  Future<void> fetchFloorsForProperty(int propId) async {
    try {
      final res = await apiService.getApi(ConstantUri.propertyFloors(propId));
      if (res != null) {
        final decoded = res is Map ? res : jsonDecode(res.toString());
        final data = decoded['data'];
        List items = [];
        if (data != null) {
          if (data is Map && data['content'] is List) {
            items = data['content'];
          } else if (data is List) {
            items = data;
          }
        }
        if (currentProperty.value?.id == propId) {
          totalFloors.value = items.length;
        }
      }
    } catch (_) {}
  }

  Future<void> fetchVisitRequestsStats() async {
    try {
      final activeId = currentProperty.value?.id;
      final Set<int> propertyIds = {};
      for (var p in myProperties) {
        if (p.id != null) propertyIds.add(p.id!);
      }
      if (activeId != null) propertyIds.add(activeId);

      final List<VisitRequestModel> allFetched = [];
      await Future.wait(propertyIds.map((propId) async {
        try {
          final res = await apiService.getApi(ConstantUri.ownerVisitRequests(propId));
          if (res != null) {
            final decoded = res is Map ? res : jsonDecode(res.toString());
            final data = decoded['data'];
            List items = [];
            if (data != null) {
              if (data is Map && data['content'] is List) {
                items = data['content'];
              } else if (data is List) {
                items = data;
              }
            }
            allFetched.addAll(items.map((e) => VisitRequestModel.fromJson(Map<String, dynamic>.from(e))));
          }
        } catch (_) {}
      }));

      updateVisitRequestsStats(allFetched);
    } catch (_) {}
  }

  void updateVisitRequestsStats(List<VisitRequestModel> allRequests) {
    final activeId = currentProperty.value?.id;
    final pendingActive = allRequests.where((r) =>
        (r.status ?? '').toUpperCase() == "PENDING" &&
        (activeId == null || r.propertyId == activeId)).toList();

    final allPending = allRequests.where((r) =>
        (r.status ?? '').toUpperCase() == "PENDING").toList();

    pendingVisitRequestsCount.value = allPending.length;
    latestVisitRequest.value = pendingActive.isNotEmpty
        ? pendingActive.first
        : (allPending.isNotEmpty ? allPending.first : null);
  }

  Future<void> quickAcceptVisitRequest(int id) async {
    try {
      final res = await apiService.putApi(ConstantUri.acceptVisitRequest(id));
      if (res != null) {
        Get.snackbar("ជោគជ័យ", "បានយល់ព្រមទទួលការណាត់ជួប!", backgroundColor: Colors.white, colorText: AppColors.success);
        await fetchVisitRequestsStats();
        if (Get.isRegistered<OwnerVisitRequestsController>()) {
          Get.find<OwnerVisitRequestsController>().loadRequests();
        }
        if (Get.isRegistered<OwnerMainController>()) {
          Get.find<OwnerMainController>().loadDynamicNotifications();
        }
      }
    } catch (e) {
      Get.snackbar("Error", "មិនអាចយល់ព្រមបានទេ: $e", backgroundColor: Colors.white);
    }
  }

  Future<void> quickRejectVisitRequest(int id) async {
    try {
      final res = await apiService.putApi(ConstantUri.rejectVisitRequest(id));
      if (res != null) {
        Get.snackbar("បដិសេធ", "បានបដិសេធការណាត់ជួប!", backgroundColor: Colors.white, colorText: AppColors.danger);
        await fetchVisitRequestsStats();
        if (Get.isRegistered<OwnerVisitRequestsController>()) {
          Get.find<OwnerVisitRequestsController>().loadRequests();
        }
        if (Get.isRegistered<OwnerMainController>()) {
          Get.find<OwnerMainController>().loadDynamicNotifications();
        }
      }
    } catch (e) {
      Get.snackbar("Error", "មិនអាចបដិសេធបានទេ: $e", backgroundColor: Colors.white);
    }
  }

  /// Get building image source from property or fallback sources
  String? getBuildingImageSource(PropertyModel? property) {
    if (property == null) return null;

    // 1. Check user-scoped local storage override if user customized it
    if (property.id != null) {
      try {
        final box = GetStorage();
        final localKey = TokenStoreLocal.getUserScopedKey("PROPERTY_IMG_${property.id}");
        final localImg = box.read(localKey);
        if (localImg != null && localImg.toString().trim().isNotEmpty) {
          return localImg.toString().trim();
        }
      } catch (_) {}
    }

    // 2. Check property.mainImage
    if (property.mainImage != null && property.mainImage!.trim().isNotEmpty) {
      return property.mainImage!.trim();
    }

    // 3. Check property.images (first non-empty)
    if (property.images != null && property.images!.trim().isNotEmpty) {
      final list = property.images!.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (list.isNotEmpty) return list.first;
    }

    // 4. Check OwnerMainController propertiesList
    if (Get.isRegistered<OwnerMainController>()) {
      final mainCtrl = Get.find<OwnerMainController>();
      final match = mainCtrl.propertiesList.firstWhereOrNull((p) => p['id'] == property.id);
      final mImg = match?['mainImage']?.toString();
      if (mImg != null && mImg.trim().isNotEmpty) {
        return mImg.trim();
      }
    }

    // 5. Check if any room has an image
    if (property.rooms != null && property.rooms!.isNotEmpty) {
      for (final r in property.rooms!) {
        if (r.images != null && r.images!.trim().isNotEmpty) {
          final rImgs = r.images!.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          if (rImgs.isNotEmpty) return rImgs.first;
        }
      }
    }

    // 6. Default to the BBU Takeo building photo
    return "assets/images/bbu_building.png";
  }

  /// Pick and upload a new building background photo
  Future<void> updateBuildingPhoto(ImageSource source) async {
    final prop = currentProperty.value;
    if (prop == null || prop.id == null) {
      Get.snackbar(
        LanguageService.isKhmer ? "បញ្ហា" : "Notice",
        LanguageService.isKhmer ? "សូមជ្រើសរើសអគារជាមុនសិន" : "Please select a property first",
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      String newImageSource = "data:image/jpeg;base64,${base64Encode(bytes)}";

      // Try server upload in background
      try {
        final uri = Uri.parse("${ConstantUri.baseUri}/app/public/v1/image/upload");
        final req = http.MultipartRequest("POST", uri);
        if (kIsWeb) {
          req.files.add(http.MultipartFile.fromBytes('File', bytes, filename: picked.name));
        } else {
          req.files.add(await http.MultipartFile.fromPath('File', picked.path));
        }
        final token = TokenStoreLocal.getAccessToken();
        if (token.isNotEmpty) {
          req.headers['Authorization'] = 'Bearer $token';
        }
        final streamed = await req.send().timeout(const Duration(seconds: 15));
        final res = await http.Response.fromStream(streamed);
        if (res.statusCode == 200 || res.statusCode == 201) {
          final decoded = jsonDecode(utf8.decode(res.bodyBytes));
          final data = decoded['data'];
          String? fileName;
          if (data is Map) {
            fileName = data['fileName']?.toString() ?? data['data']?.toString() ?? data['filename']?.toString();
          } else if (data is String) {
            fileName = data;
          }
          if (fileName != null && fileName.isNotEmpty) {
            newImageSource = "${ConstantUri.baseUri}/api/public/view/image?filename=$fileName";
          }
        }
      } catch (e) {
        debugPrint("Error uploading building photo: $e");
      }

      // 1. Save to local storage for instant persistence
      try {
        final box = GetStorage();
        final localKey = TokenStoreLocal.getUserScopedKey("PROPERTY_IMG_${prop.id}");
        box.write(localKey, newImageSource);
      } catch (_) {}

      // 2. Try server update
      try {
        await apiService.putApi(
          ConstantUri.propertyDetail(prop.id!),
          body: {"mainImage": newImageSource},
        );
      } catch (_) {}

      // 3. Update active PropertyModel
      final updated = PropertyModel(
        id: prop.id,
        name: prop.name,
        description: prop.description,
        propertyType: prop.propertyType,
        address: prop.address,
        city: prop.city,
        district: prop.district,
        latitude: prop.latitude,
        longitude: prop.longitude,
        status: prop.status,
        verificationStatus: prop.verificationStatus,
        mainImage: newImageSource,
        images: prop.images,
        owner: prop.owner,
        rooms: prop.rooms,
        minRoomPrice: prop.minRoomPrice,
        availableRoomCount: prop.availableRoomCount,
        totalRoomCount: prop.totalRoomCount,
        averageRating: prop.averageRating,
        reviewCount: prop.reviewCount,
        createdAt: prop.createdAt,
        updatedAt: prop.updatedAt,
      );

      currentProperty.value = updated;
      final idx = myProperties.indexWhere((p) => p.id == prop.id);
      if (idx != -1) {
        myProperties[idx] = updated;
      }

      // 4. Update OwnerMainController list
      if (Get.isRegistered<OwnerMainController>()) {
        final mainCtrl = Get.find<OwnerMainController>();
        final mIdx = mainCtrl.propertiesList.indexWhere((p) => p['id'] == prop.id);
        if (mIdx != -1) {
          mainCtrl.propertiesList[mIdx]['mainImage'] = newImageSource;
          mainCtrl.propertiesList.refresh();
        }
      }

      Get.snackbar(
        LanguageService.isKhmer ? "ជោគជ័យ" : "Success",
        LanguageService.isKhmer ? "បានប្តូររូបភាពអគាររួចរាល់!" : "Building photo updated successfully!",
        backgroundColor: Colors.white,
        colorText: AppColors.textPrimary,
        icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
      );
    } catch (e) {
      Get.snackbar("Error", "Could not pick image: $e", backgroundColor: Colors.white);
    }
  }

  /// Reset building photo to original
  void resetBuildingPhoto() {
    final prop = currentProperty.value;
    if (prop == null || prop.id == null) return;
    try {
      final box = GetStorage();
      final localKey = TokenStoreLocal.getUserScopedKey("PROPERTY_IMG_${prop.id}");
      box.remove(localKey);
    } catch (_) {}

    // Find original property from API response if any
    final match = myProperties.firstWhereOrNull((p) => p.id == prop.id);
    currentProperty.value = match ?? prop;
    currentProperty.refresh();

    Get.snackbar(
      LanguageService.isKhmer ? "បានកំណត់ឡើងវិញ" : "Reset",
      LanguageService.isKhmer ? "បានកំណត់រូបភាពអគារដើមឡើងវិញរួចរាល់" : "Reset to default building photo",
      backgroundColor: Colors.white,
      colorText: AppColors.textPrimary,
    );
  }
}
