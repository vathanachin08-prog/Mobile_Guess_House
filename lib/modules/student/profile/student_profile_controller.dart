import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../constants/constant_uri.dart';
import '../../../core/services/firebase_service.dart';
import '../../../data/local/token_store_local.dart';
import '../../../routes/app_route_name.dart';

class StudentProfileController extends GetxController {
  final _storage = GetStorage();
  static const String _avatarStorageKey = "STUDENT_PROFILE_AVATAR_KEY";

  final user = Rxn<Map<String, dynamic>>();
  final profileImagePath = "".obs;
  final isUploading = false.obs;
  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    loadUser();
    fetchProfileFromServer();
  }

  void loadUser() {
    user.value = TokenStoreLocal.getUser();
    final p = user.value?['profile']?.toString() ?? '';
    if (p.isNotEmpty) {
      profileImagePath.value = p.startsWith('http')
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
    fetchProfileFromServer();
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
          profileImagePath.value = p.startsWith('http')
              ? p
              : "${ConstantUri.baseUri}/api/public/view/image?filename=$p";
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
    return 'Student User';
  }

  String get phone => user.value?['phoneNumber'] ?? '012345678';
  String get email => user.value?['email'] ?? 'student@example.com';

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
        // Convert to Base64 Data URL so it is permanently stored across web/mobile refreshes
        final base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";

        profileImagePath.value = base64Image;
        _storage.write(_avatarStorageKey, base64Image);
        Get.back(); // close bottom sheet

        // Upload to backend API
        await _uploadAvatar(picked, bytes, source: source.name);
      }
    } catch (e) {
      AppFirebaseService.logAvatarUploadForm(
        userRole: "STUDENT",
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
          userRole: "STUDENT",
          source: source,
          success: true,
        );
        try {
          final decoded = jsonDecode(utf8.decode(res.bodyBytes));
          final data = decoded['data'];
          if (data != null && data['fileName'] != null) {
            final serverFileName = data['fileName'].toString();
            final serverUrl = "${ConstantUri.baseUri}/api/public/view/image?filename=$serverFileName";
            _storage.write("${_avatarStorageKey}_SERVER_URL", serverUrl);

            // Update user profile in local store and reactive state
            final u = TokenStoreLocal.getUser() ?? {};
            u['profile'] = serverFileName;
            TokenStoreLocal.setUser(u);
            user.value = u;
            profileImagePath.value = serverUrl;

            // Persist to database users table so it stays permanently after logout/close!
            await _saveProfileToDatabase(serverFileName, token);
          }
        } catch (_) {}

        Get.snackbar(
          "ជោគជ័យ / Success",
          "រូបភាពប្រវត្តិរូបត្រូវបានរក្សាទុកជោគជ័យ!",
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade900,
        );
      } else {
        AppFirebaseService.logAvatarUploadForm(
          userRole: "STUDENT",
          source: source,
          success: false,
          errorMessage: "Status code: ${res.statusCode}",
        );
      }
    } catch (e) {
      AppFirebaseService.logAvatarUploadForm(
        userRole: "STUDENT",
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
    if (Get.locale?.languageCode == 'km') {
      Get.updateLocale(const Locale('en', 'US'));
    } else {
      Get.updateLocale(const Locale('km', 'KH'));
    }
  }

  void logout() {
    TokenStoreLocal.removeToken();
    Get.offAllNamed(AppRouteName.login);
  }
}
