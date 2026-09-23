import 'package:get_storage/get_storage.dart';

class TokenStoreLocal {
  static final storage = GetStorage();
  static final String _accessToken = "ACCESS_TOKEN";
  static final String _refreshToken = "REFRESH_TOKEN";

  static final String _user = "USER_DATA";
  static final String _userRole = "USER_ROLE";

  static void setAccessToken(String token) {
    storage.write(_accessToken, token);
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
  }
}
