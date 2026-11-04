import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get_storage/get_storage.dart';

class ConstantUri {
  static final GetStorage _storage = GetStorage();
  static const String serverStorageKey = "CUSTOM_SERVER_BASE_URI";

  /// Returns the dynamically configured or smart default base URI
  static String get baseUri {
    final custom = _storage.read(serverStorageKey);
    if (custom != null && custom.toString().trim().isNotEmpty) {
      return custom.toString().trim();
    }
    return defaultBaseUri;
  }

  /// Platform-aware default server base URI
  static String get defaultBaseUri {
    if (kIsWeb) {
      return "http://localhost:30033";
    }
    try {
      if (Platform.isAndroid) {
        // Standard Android emulator loopback to host computer
        return "http://10.0.2.2:30033";
      }
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        return "http://localhost:30033";
      }
    } catch (_) {}
    return "http://localhost:30033";
  }

  /// Sets and persists a new server base URI at runtime
  static void setBaseUri(String uri) {
    var clean = uri.trim();
    if (clean.endsWith("/")) {
      clean = clean.substring(0, clean.length - 1);
    }
    _storage.write(serverStorageKey, clean);
  }

  /// Resets back to platform default
  static void resetToDefault() {
    _storage.remove(serverStorageKey);
  }

  // Auth Endpoints
  static String get login => "$baseUri/api/oauth/token";
  static String get register => "$baseUri/api/oauth/register";
  static String get refreshToken => "$baseUri/api/oauth/refresh";

  // Products & Categories
  static String get products => "$baseUri/api/app/product/list";
  static String get productBase => "$baseUri/api/app/product";
  static String get productCategories => "$baseUri/api/app/product/category/list";
  static String productDetail(dynamic id) => "$baseUri/api/app/product/$id";

  // Employees
  static String get employees => "$baseUri/api/app/employees";
  static String employeeDetail(dynamic id) => "$baseUri/api/app/employees/$id";

  // Public Rental Endpoints
  static String get publicProperties => "$baseUri/api/public/properties";
  static String publicPropertyDetail(dynamic id) => "$baseUri/api/public/properties/$id";
  static String publicRoomDetail(dynamic id) => "$baseUri/api/public/rooms/$id";
  static String publicReviews(dynamic propertyId) => "$baseUri/api/public/properties/$propertyId/reviews";

  // Owner & Authenticated Endpoints
  static String get properties => "$baseUri/api/app/properties";
  static String get myProperties => "$baseUri/api/app/properties/my";
  static String propertyDetail(dynamic id) => "$baseUri/api/app/properties/$id";
  static String propertyRooms(dynamic propertyId) => "$baseUri/api/app/properties/$propertyId/rooms";
  static String roomDetail(dynamic id) => "$baseUri/api/app/rooms/$id";
  static String propertyFloors(dynamic propertyId) => "$baseUri/api/app/properties/$propertyId/floors";
  static String deleteFloor(dynamic id) => "$baseUri/api/app/floors/$id";
  static String propertyTenants(dynamic propertyId) => "$baseUri/api/app/properties/$propertyId/tenants";
  static String tenantDetail(dynamic id) => "$baseUri/api/app/tenants/$id";

  // Student Favorites
  static String get favorites => "$baseUri/api/app/favorites";
  static String deleteFavorite(dynamic id) => "$baseUri/api/app/favorites/$id";
  static String deleteFavoriteByProperty(dynamic propertyId) => "$baseUri/api/app/favorites/property/$propertyId";

  // Visit Requests
  static String get visitRequests => "$baseUri/api/app/visit-requests";
  static String get myVisitRequests => "$baseUri/api/app/visit-requests/my";
  static String ownerVisitRequests(dynamic propertyId) => "$baseUri/api/app/owner/visit-requests/$propertyId";
  static String acceptVisitRequest(dynamic id) => "$baseUri/api/app/visit-requests/$id/accept";
  static String rejectVisitRequest(dynamic id) => "$baseUri/api/app/visit-requests/$id/reject";
  static String cancelVisitRequest(dynamic id) => "$baseUri/api/app/visit-requests/$id/cancel";
  static String completeVisitRequest(dynamic id) => "$baseUri/api/app/visit-requests/$id/complete";

  // Reviews & Reports
  static String propertyReviews(dynamic propertyId) => "$baseUri/api/app/properties/$propertyId/reviews";
  static String propertyReports(dynamic propertyId) => "$baseUri/api/app/properties/$propertyId/reports";

  // Legacy demo
  static String get getAllPostPath => "$baseUri/api/app/post";

  // Support & Social
  static const String telegramSupportUrl = "https://t.me/OuknhaTK";
}
