import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../constants/constant_uri.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/language_service.dart';
import '../../../data/local/token_store_local.dart';
import '../dashboard/owner_dashboard_controller.dart';
import '../owner_main_controller.dart';

class OwnerProfileController extends GetxController {
  final _storage = GetStorage();
  String get _avatarStorageKey => TokenStoreLocal.getUserScopedKey("OWNER_PROFILE_AVATAR_KEY");
  String get _membershipPlanStorageKey => TokenStoreLocal.getUserScopedKey("OWNER_MEMBERSHIP_PLAN");

  final user = Rxn<Map<String, dynamic>>();
  final profileImagePath = "".obs;
  final isUploading = false.obs;
  final ImagePicker _picker = ImagePicker();

  final propertiesCount = 0.obs;
  final membershipPlan = "BASIC".obs;

  @override
  void onInit() {
    super.onInit();
    loadUser();
    loadPlan();
    fetchProfileFromServer();
    fetchPropertiesCount();
  }

  void loadUser() {
    profileImagePath.value = "";
    user.value = TokenStoreLocal.getUser();
    final p = user.value?['profile']?.toString() ?? '';
    if (p.isNotEmpty) {
      profileImagePath.value = p.startsWith('http') || p.startsWith('data:image')
          ? p
          : "${ConstantUri.baseUri}/api/public/view/image?filename=$p";
      return;
    }

    final serverUrl = _storage.read("${_avatarStorageKey}_SERVER_URL");
    if (serverUrl != null && serverUrl.toString().isNotEmpty) {
      profileImagePath.value = serverUrl.toString();
      return;
    }

    final savedAvatar = _storage.read(_avatarStorageKey);
    if (savedAvatar != null && savedAvatar.toString().isNotEmpty) {
      profileImagePath.value = savedAvatar.toString();
    }
  }

  @override
  void onReady() {
    super.onReady();
    loadUser();
    loadPlan();
    fetchProfileFromServer();
    fetchPropertiesCount();
  }

  Future<void> fetchProfileFromServer() async {
    final token = TokenStoreLocal.getAccessToken();
    if (token.isEmpty) return;

    // 1. Try GET /api/app/user/me
    try {
      final res = await http.get(
        Uri.parse("${ConstantUri.baseUri}/api/app/user/me"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        _applyUserData(res.bodyBytes);
        return;
      }
    } catch (_) {}

    // 2. Fallback to POST /api/app/user/{id} which already exists on running backend
    try {
      final userId = user.value?['id'] ?? TokenStoreLocal.getUser()?['id'];
      if (userId != null) {
        final res = await http.post(
          Uri.parse("${ConstantUri.baseUri}/api/app/user/$userId"),
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({}),
        ).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          _applyUserData(res.bodyBytes);
          return;
        }
      }
    } catch (_) {}
  }

  void _applyUserData(Uint8List bodyBytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bodyBytes));
      final data = decoded['data'] ?? decoded;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        TokenStoreLocal.setUser(map);
        user.value = map;
        final p = map['profile']?.toString() ?? '';
        if (p.isNotEmpty) {
          final resolvedUrl = p.startsWith('http') || p.startsWith('data:image')
              ? p
              : "${ConstantUri.baseUri}/api/public/view/image?filename=$p";
          profileImagePath.value = resolvedUrl;
          _storage.write("${_avatarStorageKey}_SERVER_URL", resolvedUrl);
        }
      }
    } catch (_) {}
  }

  String get displayName {
    final u = user.value;
    if (u != null) {
      final f = u['firstName'] ?? '';
      final l = u['lastName'] ?? '';
      if (f.isNotEmpty) return "$f $l".trim();
      final username = u['username'] ?? '';
      if (username.isNotEmpty) return username;
    }
    return "ម្ចាស់អគារ (Owner)";
  }

  String get phone => user.value?['phoneNumber'] ?? '098765432';
  String get email => user.value?['email'] ?? 'owner@roomfinderkh.com';
  String get propertyName => "My Home (អគារផ្ទះជួល)";

  void loadPlan() {
    final saved = _storage.read(_membershipPlanStorageKey);
    if (saved != null && saved.toString().isNotEmpty) {
      membershipPlan.value = saved.toString().toUpperCase();
      return;
    }
    final uPlan = user.value?['membershipPlan'] ?? user.value?['plan'];
    if (uPlan != null && uPlan.toString().isNotEmpty) {
      membershipPlan.value = uPlan.toString().toUpperCase();
      return;
    }
    membershipPlan.value = "BASIC";
  }

  void setPlan(String planName) {
    membershipPlan.value = planName.toUpperCase();
    _storage.write(_membershipPlanStorageKey, planName.toUpperCase());
  }

  Future<void> fetchPropertiesCount() async {
    try {
      final token = TokenStoreLocal.getAccessToken();
      if (token.isEmpty) return;
      final res = await http.get(
        Uri.parse(ConstantUri.myProperties),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        final data = decoded['data'];
        List items = [];
        if (data != null) {
          if (data is Map && data['content'] is List) {
            items = data['content'];
          } else if (data is List) {
            items = data;
          }
        }
        propertiesCount.value = items.length;
      }
    } catch (_) {}
  }

  int get totalBuildingsCount {
    if (Get.isRegistered<OwnerMainController>()) {
      final mainCtrl = Get.find<OwnerMainController>();
      if (mainCtrl.propertiesList.isNotEmpty) {
        return mainCtrl.propertiesList.length;
      }
    }
    if (Get.isRegistered<OwnerDashboardController>()) {
      final dashCtrl = Get.find<OwnerDashboardController>();
      if (dashCtrl.myProperties.isNotEmpty) {
        return dashCtrl.myProperties.length;
      }
    }
    return propertiesCount.value;
  }

  String get locationDisplay {
    String? rawLoc;

    // 1. Try selected property from OwnerMainController
    if (Get.isRegistered<OwnerMainController>()) {
      final mainCtrl = Get.find<OwnerMainController>();
      final selectedId = mainCtrl.selectedPropertyId.value;
      final prop = mainCtrl.propertiesList.firstWhereOrNull((p) => p['id'] == selectedId)
          ?? (mainCtrl.propertiesList.isNotEmpty ? mainCtrl.propertiesList.first : null);
      if (prop != null) {
        final city = prop['city']?.toString().trim();
        final district = prop['district']?.toString().trim();
        final address = prop['address']?.toString().trim();
        if (city != null && city.isNotEmpty) {
          rawLoc = city;
        } else if (district != null && district.isNotEmpty) {
          rawLoc = district;
        } else if (address != null && address.isNotEmpty) {
          rawLoc = address;
        }
      }
    }

    // 2. Fallback to OwnerDashboardController currentProperty
    if ((rawLoc == null || rawLoc.isEmpty) && Get.isRegistered<OwnerDashboardController>()) {
      final dashCtrl = Get.find<OwnerDashboardController>();
      final prop = dashCtrl.currentProperty.value;
      if (prop != null) {
        if (prop.city != null && prop.city!.trim().isNotEmpty) {
          rawLoc = prop.city!.trim();
        } else if (prop.district != null && prop.district!.trim().isNotEmpty) {
          rawLoc = prop.district!.trim();
        } else if (prop.address != null && prop.address!.trim().isNotEmpty) {
          rawLoc = prop.address!.trim();
        }
      }
    }

    // 3. Fallback to user model's city/address
    if (rawLoc == null || rawLoc.isEmpty) {
      final u = user.value ?? TokenStoreLocal.getUser();
      final uCity = u?['city']?.toString().trim();
      final uAddr = u?['address']?.toString().trim();
      if (uCity != null && uCity.isNotEmpty) {
        rawLoc = uCity;
      } else if (uAddr != null && uAddr.isNotEmpty) {
        rawLoc = uAddr;
      }
    }

    // 4. Default fallback if nothing specified
    if (rawLoc == null || rawLoc.isEmpty) {
      return 'building_location'.tr;
    }

    // Standardize Phnom Penh variations between EN and KH
    final lower = rawLoc.toLowerCase();
    if (lower == 'phnom penh' || rawLoc == 'ភ្នំពេញ' || rawLoc == 'រាជធានីភ្នំពេញ') {
      return 'building_location'.tr;
    }

    // If rawLoc has multiple comma-separated sections (e.g. "Khan Daun Penh, Phnom Penh"),
    // extract the city or the most relevant district part to keep it clean in stat card
    if (rawLoc.contains(',')) {
      final parts = rawLoc.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        final last = parts.last;
        if (last.toLowerCase() == 'phnom penh' || last == 'ភ្នំពេញ' || last == 'រាជធានីភ្នំពេញ') {
          return parts.length > 1 ? parts[parts.length - 2] : 'building_location'.tr;
        }
        return last;
      }
    }

    return rawLoc;
  }

  String get planDisplay {
    final p = membershipPlan.value.toUpperCase();
    if (p == 'STANDARD') {
      return 'membership_plan_standard'.tr;
    } else if (p == 'PREMIUM') {
      return 'membership_plan_premium'.tr;
    }
    return 'membership_plan_free'.tr;
  }

  String get planBadgeText {
    final p = membershipPlan.value.toUpperCase();
    if (p == 'STANDARD') return "Standard";
    if (p == 'PREMIUM') return "Premium";
    return "Free";
  }

  Future<void> pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";

        profileImagePath.value = base64Image;
        _storage.write(_avatarStorageKey, base64Image);
        if (Get.isRegistered<OwnerDashboardController>()) {
          Get.find<OwnerDashboardController>().profileImagePath.value = base64Image;
        }
        Get.back(); // close bottom sheet

        // Upload to Spring Boot Backend API
        await _uploadAvatar(picked, bytes, source: source.name);
      }
    } catch (e) {
      AppFirebaseService.logAvatarUploadForm(
        userRole: "OWNER",
        source: source.name,
        success: false,
        errorMessage: e.toString(),
      );
      Get.snackbar(
        "Error",
        "មិនអាចជ្រើសរើសរូបភាពបានទេ: ${e.toString()}",
        backgroundColor: Colors.red.shade50,
      );
    }
  }

  Future<void> _uploadAvatar(XFile file, Uint8List bytes, {String source = "picker"}) async {
    isUploading.value = true;
    try {
      final uri = Uri.parse("${ConstantUri.baseUri}/app/public/v1/image/upload");
      final req = http.MultipartRequest("POST", uri);

      if (kIsWeb) {
        req.files.add(http.MultipartFile.fromBytes('File', bytes, filename: file.name));
      } else {
        req.files.add(await http.MultipartFile.fromPath('File', file.path));
      }

      final token = TokenStoreLocal.getAccessToken();
      if (token.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer $token';
      }

      final streamedResponse = await req.send().timeout(const Duration(seconds: 15));
      final res = await http.Response.fromStream(streamedResponse);

      if (res.statusCode == 200 || res.statusCode == 201) {
        AppFirebaseService.logAvatarUploadForm(
          userRole: "OWNER",
          source: source,
          success: true,
        );
        try {
          final decoded = jsonDecode(utf8.decode(res.bodyBytes));
          final data = decoded['data'];
          String? serverFileName;
          if (data is Map) {
            serverFileName = data['fileName']?.toString() ??
                data['data']?.toString() ??
                data['filename']?.toString();
          } else if (data is String) {
            serverFileName = data;
          }

          if (serverFileName != null && serverFileName.isNotEmpty) {
            final serverUrl = "${ConstantUri.baseUri}/api/public/view/image?filename=$serverFileName";
            _storage.write("${_avatarStorageKey}_SERVER_URL", serverUrl);

            final u = TokenStoreLocal.getUser() ?? {};
            u['profile'] = serverFileName;
            TokenStoreLocal.setUser(u);
            user.value = u;
            profileImagePath.value = serverUrl;
            if (Get.isRegistered<OwnerDashboardController>()) {
              Get.find<OwnerDashboardController>().profileImagePath.value = serverUrl;
            }

            // Persist to database users table so it stays permanently after logout/close!
            await _saveProfileToDatabase(serverFileName, token);
          }
        } catch (_) {}

        Get.snackbar(
          'success'.tr,
          'avatar_saved_success'.tr,
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade900,
        );
      } else {
        AppFirebaseService.logAvatarUploadForm(
          userRole: "OWNER",
          source: source,
          success: false,
          errorMessage: "Status code: ${res.statusCode}",
        );
      }
    } catch (e) {
      AppFirebaseService.logAvatarUploadForm(
        userRole: "OWNER",
        source: source,
        success: false,
        errorMessage: e.toString(),
      );
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> _saveProfileToDatabase(String fileName, String token) async {
    try {
      // 1. Try dedicated avatar update endpoint
      final avatarUri = Uri.parse("${ConstantUri.baseUri}/api/app/user/avatar");
      final avatarRes = await http.post(
        avatarUri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"fileName": fileName}),
      );

      if (avatarRes.statusCode == 200 || avatarRes.statusCode == 201) {
        return;
      }

      // 2. Fallback to /api/app/user/update
      final u = TokenStoreLocal.getUser();
      if (u != null && u['id'] != null) {
        final updateUri = Uri.parse("${ConstantUri.baseUri}/api/app/user/update");
        final body = Map<String, dynamic>.from(u);
        body['profile'] = fileName;
        await http.post(
          updateUri,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode(body),
        );
      }
    } catch (e) {
      debugPrint("Error saving profile to database: $e");
    }
  }

  void toggleLanguage() {
    LanguageService.toggleLanguage();
  }

  void logout() {
    TokenStoreLocal.removeToken();
  }
}
