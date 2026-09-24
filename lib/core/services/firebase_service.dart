import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class AppFirebaseService {
  AppFirebaseService._();

  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

  /// Observer សម្រាប់ដាក់ក្នុង GetMaterialApp(navigatorObservers: [FirebaseService.observer])
  /// ដើម្បី Track screen navigation ដោយស្វ័យប្រវត្តិ
  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: analytics);

  // -------------------------------------------------------------
  // 1. SETUP & INIT REMOTE CONFIG
  // -------------------------------------------------------------
  static Future<void> initRemoteConfig() async {
    try {
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        // ក្នុងពេល Develop ដាក់ Duration.zero ដើម្បី fetch បានភ្លាមៗ
        minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
      ));

      // កំណត់ Default values (តម្លៃលំនាំដើមពេលគ្មាន internet ឬមុនពេល fetch)
      await remoteConfig.setDefaults(const {
        "welcome_message": "សូមស្វាគមន៍មកកាន់ RoomFinder KH",
        "maintenance_mode": false,
        "khr_exchange_rate": 4100,
        "enable_khqr_payment": true,
      });

      // ទាញយកទិន្នន័យពី Firebase Console
      await remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint("Remote Config Error: $e");
    }
  }

  /// ហៅ Fetch ទិន្នន័យ Remote Config ឡើងវិញភ្លាមៗ
  static Future<bool> fetchRemoteConfig() async {
    try {
      return await remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint("Remote Config Fetch Error: $e");
      return false;
    }
  }

  // Getters សម្រាប់ទាញយកតម្លៃ Remote Config
  static String get welcomeMessage => remoteConfig.getString("welcome_message");
  static bool get isMaintenanceMode => remoteConfig.getBool("maintenance_mode");
  static int get exchangeRate {
    final val = remoteConfig.getInt("khr_exchange_rate");
    if (val != 0) return val;
    final str = remoteConfig.getString("khr_exchange_rate").trim();
    return int.tryParse(str) ?? 4100;
  }
  static bool get enableKhqr => remoteConfig.getBool("enable_khqr_payment");

  // -------------------------------------------------------------
  // 2. FIREBASE ANALYTICS TRACKING
  // -------------------------------------------------------------

  /// 1. Track ពេល User ចូលមើល Screen
  static Future<void> logScreen(String screenName) async {
    await analytics.logScreenView(screenClass: screenName, screenName: screenName);
  }

  /// 2. Track ពេល User Login ជោគជ័យ
  static Future<void> logLogin({required String method, required String role, String? userId}) async {
    await analytics.logLogin(loginMethod: method);
    if (userId != null && userId.isNotEmpty) {
      await analytics.setUserId(id: userId);
    }
    await analytics.setUserProperty(name: "user_role", value: role);
  }

  /// 3. Track ពេល User ស្វែងរកបន្ទប់ជួល (Search)
  static Future<void> logSearch(String searchTerm) async {
    await analytics.logSearch(searchTerm: searchTerm);
  }

  /// 4. Track ពេល User មើលព័ត៌មានលម្អិតបន្ទប់ (View Room Detail)
  static Future<void> logViewRoom({required String roomId, required String roomTitle, required double price}) async {
    await analytics.logEvent(
      name: "view_room_detail",
      parameters: {
        "room_id": roomId,
        "room_title": roomTitle,
        "price": price,
      },
    );
  }

  /// 5. Track ពេល User ចុចកក់ការណាត់ជួប (Book Visit Request)
  static Future<void> logBookVisit({required String propertyId, required String visitDate}) async {
    await analytics.logEvent(
      name: "book_visit_request",
      parameters: {
        "property_id": propertyId,
        "visit_date": visitDate,
      },
    );
  }

  /// 6. Track ពេល User Save / Favorite បន្ទប់
  static Future<void> logToggleFavorite({required String roomId, required bool isFavorite}) async {
    await analytics.logEvent(
      name: "toggle_favorite",
      parameters: {
        "room_id": roomId,
        "action": isFavorite ? "save" : "unsave",
      },
    );
  }

  /// 7. Track សកម្មភាពរបស់ម្ចាស់ផ្ទះជួល (Owner Action)
  static Future<void> logOwnerAction(String action, {Map<String, Object>? details}) async {
    await analytics.logEvent(
      name: "owner_action",
      parameters: {
        "action": action,
        ...?details,
      },
    );
  }

  /// 8. Custom General Event ផ្សេងៗ
  static Future<void> logCustomEvent(String name, {Map<String, Object>? parameters}) async {
    await analytics.logEvent(name: name, parameters: parameters);
  }

  // -------------------------------------------------------------
  // 3. FORM ANALYTICS TRACKING (TRACK ALL FORMS)
  // -------------------------------------------------------------

  /// Generic Form Tracking method
  static Future<void> logFormSubmit({
    required String formName,
    required bool success,
    String? errorMessage,
    Map<String, Object>? parameters,
  }) async {
    try {
      final params = <String, Object>{
        "form_name": formName,
        "success": success ? "true" : "false",
        if (errorMessage != null && errorMessage.isNotEmpty) "error_message": errorMessage,
        ...?parameters,
      };
      await analytics.logEvent(
        name: "form_submission",
        parameters: params,
      );
    } catch (e) {
      debugPrint("Firebase Analytics logFormSubmit error: $e");
    }
  }

  /// 1. Track Login Form
  static Future<void> logLoginForm({
    required bool success,
    String? role,
    String? userId,
    String? errorMessage,
  }) async {
    await logFormSubmit(
      formName: "login_form",
      success: success,
      errorMessage: errorMessage,
      parameters: {
        if (role != null) "role": role,
      },
    );
    if (success && role != null) {
      await logLogin(method: "phone_password", role: role, userId: userId);
    }
  }

  /// 2. Track Register Form
  static Future<void> logRegisterForm({
    required bool success,
    required String role,
    String? errorMessage,
  }) async {
    await logFormSubmit(
      formName: "register_form",
      success: success,
      errorMessage: errorMessage,
      parameters: {
        "role": role,
      },
    );
    if (success) {
      try {
        await analytics.logSignUp(signUpMethod: "phone_number");
        await analytics.setUserProperty(name: "user_role", value: role);
      } catch (_) {}
    }
  }

  /// 3. Track Book Visit Request Form
  static Future<void> logVisitRequestForm({
    required int propertyId,
    int? roomId,
    required String requestedDate,
    required bool success,
    String? errorMessage,
  }) async {
    await logFormSubmit(
      formName: "visit_request_form",
      success: success,
      errorMessage: errorMessage,
      parameters: {
        "property_id": propertyId,
        if (roomId != null) "room_id": roomId,
        "requested_date": requestedDate,
      },
    );
    if (success) {
      await logBookVisit(propertyId: propertyId.toString(), visitDate: requestedDate);
    }
  }

  /// 4. Track Review & Rating Form
  static Future<void> logReviewForm({
    required int propertyId,
    required int rating,
    required bool success,
    String? errorMessage,
  }) async {
    await logFormSubmit(
      formName: "review_form",
      success: success,
      errorMessage: errorMessage,
      parameters: {
        "property_id": propertyId,
        "rating": rating,
      },
    );
  }

  /// 5. Track Owner Pricing & Utilities Settings Form
  static Future<void> logPricingSettingsForm({
    required double rentPrice,
    required String electricity,
    required String water,
    required String exchangeRate,
    required bool success,
  }) async {
    await logFormSubmit(
      formName: "pricing_settings_form",
      success: success,
      parameters: {
        "rent_price": rentPrice,
        "electricity": electricity,
        "water": water,
        "exchange_rate": exchangeRate,
      },
    );
  }

  /// 6. Track Owner Add Room Form
  static Future<void> logAddRoomForm({
    required String roomNumber,
    required int floor,
    required double price,
    required bool success,
    String? errorMessage,
  }) async {
    await logFormSubmit(
      formName: "add_room_form",
      success: success,
      errorMessage: errorMessage,
      parameters: {
        "room_number": roomNumber,
        "floor": floor,
        "price": price,
      },
    );
  }

  /// 7. Track Owner Add Floor Form
  static Future<void> logAddFloorForm({
    required String floorName,
    required bool success,
    String? errorMessage,
  }) async {
    await logFormSubmit(
      formName: "add_floor_form",
      success: success,
      errorMessage: errorMessage,
      parameters: {
        "floor_name": floorName,
      },
    );
  }

  /// 8. Track Owner Add Tenant Form
  static Future<void> logAddTenantForm({
    required String tenantName,
    required String roomNumber,
    required bool success,
  }) async {
    await logFormSubmit(
      formName: "add_tenant_form",
      success: success,
      parameters: {
        "tenant_name": tenantName,
        "room_number": roomNumber,
      },
    );
  }

  /// 9. Track Profile Avatar Upload Form
  static Future<void> logAvatarUploadForm({
    required String userRole,
    required String source,
    required bool success,
    String? errorMessage,
  }) async {
    await logFormSubmit(
      formName: "avatar_upload_form",
      success: success,
      errorMessage: errorMessage,
      parameters: {
        "user_role": userRole,
        "source": source,
      },
    );
  }

  /// 10. Track Student Search Form
  static Future<void> logSearchForm({
    required String keyword,
    int? resultCount,
  }) async {
    await logFormSubmit(
      formName: "search_form",
      success: true,
      parameters: {
        "keyword": keyword,
        if (resultCount != null) "result_count": resultCount,
      },
    );
    await logSearch(keyword);
  }
}
