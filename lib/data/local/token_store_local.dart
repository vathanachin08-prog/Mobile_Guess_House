import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/services/api_service.dart';
import '../../core/services/api_service_impl.dart';
import '../../modules/login/login_controller.dart';
import '../../routes/app_route_name.dart';

class TokenStoreLocal {
  static final storage = GetStorage();
  static final String _accessToken = "ACCESS_TOKEN";
  static final String _refreshToken = "REFRESH_TOKEN";

  static final String _user = "USER_DATA";
  static final String _userRole = "USER_ROLE";

  static void setAccessToken(String token) {
    storage.write(_accessToken, token);
    _decodeAndSaveTokenClaims(token);
  }

  static void _decodeAndSaveTokenClaims(String token) {
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final normalized = base64Url.normalize(parts[1]);
        final decoded = jsonDecode(utf8.decode(base64Url.decode(normalized)));
        if (decoded is Map) {
          final currentUser = getUser() ?? <String, dynamic>{};
          final un = decoded['user_name'] ?? decoded['sub'] ?? decoded['username'];
          if (un != null) currentUser['username'] = un.toString();
          if (decoded['id'] != null) currentUser['id'] = decoded['id'];
          if (decoded['user_id'] != null) currentUser['id'] = decoded['user_id'];
          if (decoded['authorities'] != null) {
            final auths = decoded['authorities'] as List;
            currentUser['roles'] = auths.map((a) => {'name': a.toString()}).toList();
            if (auths.isNotEmpty) {
              storage.write(_userRole, auths[0].toString());
            }
          }
          storage.write(_user, currentUser);
        }
      }
    } catch (_) {}
  }

  static void setRefreshToken(String token) {
    storage.write(_refreshToken, token);
  }

  static String getAccessToken() {
    return storage.read(_accessToken) ?? "";
  }

  static String getRefreshToken() {
    return storage.read(_refreshToken) ?? "";
  }

  static bool hasToken() {
    return getAccessToken().trim().isNotEmpty;
  }

  static void setUser(Map<String, dynamic> userJson) {
    storage.write(_user, userJson);
    if (userJson['roles'] != null && (userJson['roles'] as List).isNotEmpty) {
      final roleObj = userJson['roles'][0];
      final roleName = roleObj is Map ? (roleObj['name'] ?? '') : roleObj.toString();
      storage.write(_userRole, roleName);
    }
  }

  static Map<String, dynamic>? getUser() {
    final data = storage.read(_user);
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  static String getUserRole() {
    return storage.read(_userRole) ?? "";
  }

  static String getUserId() {
    final user = getUser();
    if (user != null) {
      if (user['id'] != null && user['id'].toString().isNotEmpty) return user['id'].toString();
      if (user['username'] != null && user['username'].toString().isNotEmpty) return user['username'].toString();
      if (user['phoneNumber'] != null && user['phoneNumber'].toString().isNotEmpty) return user['phoneNumber'].toString();
    }
    return "";
  }

  static String getUserScopedKey(String baseKey) {
    final uid = getUserId();
    return uid.isNotEmpty ? "${baseKey}_$uid" : "${baseKey}_default";
  }

  static bool isOwner() {
    final role = getUserRole();
    return role == "ROLE_OWNER" || role == "OWNER";
  }

  static bool isStudent() {
    final role = getUserRole();
    return role == "ROLE_STUDENT" || role == "STUDENT";
  }

  static String? getCurrentUserProfileImage() {
    final user = getUser();
    final p = user?['profile']?.toString() ?? '';
    if (p.isNotEmpty) return p;

    final studentKey = getUserScopedKey("STUDENT_PROFILE_AVATAR_KEY");
    final studentServerUrl = storage.read("${studentKey}_SERVER_URL");
    if (studentServerUrl != null && studentServerUrl.toString().isNotEmpty) {
      return studentServerUrl.toString();
    }
    final studentSaved = storage.read(studentKey);
    if (studentSaved != null && studentSaved.toString().isNotEmpty) {
      return studentSaved.toString();
    }

    final ownerKey = getUserScopedKey("OWNER_PROFILE_AVATAR_KEY");
    final ownerServerUrl = storage.read("${ownerKey}_SERVER_URL");
    if (ownerServerUrl != null && ownerServerUrl.toString().isNotEmpty) {
      return ownerServerUrl.toString();
    }
    final ownerSaved = storage.read(ownerKey);
    if (ownerSaved != null && ownerSaved.toString().isNotEmpty) {
      return ownerSaved.toString();
    }

    return null;
  }

  static bool _isLoggingOut = false;

  static void removeToken({bool redirect = true}) {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    try {
      storage.remove(_accessToken);
      storage.remove(_refreshToken);
      storage.remove(_user);
      storage.remove(_userRole);

      // Clean any old legacy unscoped keys
      storage.remove("OWNER_ROOMS_PERSIST_KEY");
      storage.remove("OWNER_FLOORS_PERSIST_KEY");
      storage.remove("OWNER_TENANTS_PERSIST_KEY");
      storage.remove("OWNER_INVOICES_PERSIST_KEY");
      storage.remove("OWNER_ROOMS_PERSIST_KEY_default");
      storage.remove("OWNER_FLOORS_PERSIST_KEY_default");
      storage.remove("OWNER_TENANTS_PERSIST_KEY_default");
      storage.remove("OWNER_INVOICES_PERSIST_KEY_default");

      if (redirect) {
        redirectToLogin();
      }
    } finally {
      Future.delayed(const Duration(milliseconds: 300), () {
        _isLoggingOut = false;
      });
    }
  }

  static void redirectToLogin() {
    try {
      // Ensure ApiService is available in GetX
      if (!Get.isRegistered<ApiService>()) {
        Get.put<ApiService>(ApiServiceImpl(), permanent: true);
      }

      // Ensure LoginController is registered and reset form cleanly
      if (Get.isRegistered<LoginController>()) {
        Get.find<LoginController>().resetForm();
      } else {
        Get.lazyPut<LoginController>(
          () => LoginController(apiService: Get.find<ApiService>()),
          fenix: true,
        );
      }

      // If any dialog or modal sheet is active, pop it instantly
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      final currentRoute = Get.currentRoute;
      if (currentRoute == AppRouteName.login) {
        return;
      }

      // Navigate immediately to login page
      Get.offAllNamed(AppRouteName.login);
    } catch (_) {
      try {
        Get.offAllNamed(AppRouteName.login);
      } catch (_) {}
    }
  }

  static void initTokenListener() {
    try {
      storage.listenKey(_accessToken, (value) {
        if (_isLoggingOut) return;
        if (value == null || (value is String && value.trim().isEmpty)) {
          final currentRoute = Get.currentRoute;
          if (currentRoute.isNotEmpty &&
              currentRoute != AppRouteName.login &&
              currentRoute != AppRouteName.register &&
              currentRoute != AppRouteName.splash) {
            removeToken(redirect: true);
          }
        }
      });
    } catch (_) {}
  }
}
