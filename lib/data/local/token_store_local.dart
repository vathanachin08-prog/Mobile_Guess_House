import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

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

  static void removeToken() {
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

    // Force delete active GetX controllers from RAM so next login starts 100% clean
    _disposeControllers();
  }

  static void _disposeControllers() {
    try {
      Get.deleteAll(force: true);
    } catch (_) {}
  }
}
