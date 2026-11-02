import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../models/rental/tenant_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/language_service.dart';
import '../../../data/local/token_store_local.dart';
import '../owner_main_controller.dart';
import '../dashboard/owner_dashboard_controller.dart';
import '../floors/owner_floors_controller.dart';
import '../rooms/owner_rooms_controller.dart';

class OwnerTenantsController extends GetxController {
  final ApiService? apiService;
  final _storage = GetStorage();

  int? get activePropertyId {
    if (Get.isRegistered<OwnerMainController>()) {
      return Get.find<OwnerMainController>().selectedPropertyId.value;
    }
    return null;
  }

  String get _storageKey {
    final propId = activePropertyId;
    return TokenStoreLocal.getUserScopedKey("OWNER_TENANTS_${propId ?? 'none'}");
  }

  // Legacy key for migration
  String get _legacyStorageKey => TokenStoreLocal.getUserScopedKey("OWNER_TENANTS_PERSIST_KEY");

  OwnerTenantsController({this.apiService});

  final tenants = <TenantModel>[].obs;
  final searchQuery = "".obs;
  final selectedFloorFilter = "ALL".obs;
  final isLoading = false.obs;
  final visibleLimit = 10.obs;
  final isLoadingMore = false.obs;

  void resetPagination() {
    visibleLimit.value = 10;
  }

  void loadMore() {
    final total = filteredTenants.length;
    if (visibleLimit.value < total && !isLoadingMore.value) {
      isLoadingMore.value = true;
      Future.delayed(const Duration(milliseconds: 250), () {
        visibleLimit.value = (visibleLimit.value + 5).clamp(0, total);
        isLoadingMore.value = false;
      });
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadTenants();

    // Re-load tenants whenever active property is selected or finishes loading
    if (Get.isRegistered<OwnerMainController>()) {
      ever(Get.find<OwnerMainController>().selectedPropertyId, (_) {
        loadTenants();
      });
    }
  }

  void loadTenants() {
    isLoading.value = true;
    try {
      final propId = activePropertyId;
      dynamic stored;

      // Check all possible persistent storage keys in cascade
      final candidateKeys = [
        _storageKey,
        TokenStoreLocal.getUserScopedKey("OWNER_TENANTS_${propId ?? ''}"),
        "OWNER_TENANTS_${propId ?? 'none'}",
        "OWNER_TENANTS_${propId ?? ''}",
        "GLOBAL_ALL_TENANTS",
        _legacyStorageKey,
        TokenStoreLocal.getUserScopedKey("OWNER_TENANTS_PERSIST_KEY"),
        "OWNER_TENANTS_PERSIST_KEY",
        "OWNER_TENANTS_none",
        "OWNER_TENANTS_PERSIST_KEY_default",
      ];

      for (final key in candidateKeys) {
        final val = _storage.read(key);
        if (val is List && val.isNotEmpty) {
          stored = val;
          break;
        }
      }

      if (stored is List && stored.isNotEmpty) {
        final loaded = stored
            .map((item) => TenantModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        if (propId != null) {
          final propTenants = loaded.where((t) => t.propertyId == null || t.propertyId == propId).toList();
          tenants.value = propTenants.isNotEmpty ? propTenants : loaded;
        } else {
          tenants.value = loaded;
        }
      } else {
        // Purely dynamic: empty if owner has not added tenants yet
        tenants.clear();
      }
    } catch (_) {
      tenants.clear();
    } finally {
      isLoading.value = false;
      _syncToDashboard();
    }
  }

  void _syncToDashboard() {
    if (Get.isRegistered<OwnerDashboardController>()) {
      final dashCtrl = Get.find<OwnerDashboardController>();
      if (dashCtrl.currentProperty.value?.id == activePropertyId) {
        dashCtrl.totalTenants.value = tenants.length;
      }
    }
  }

  void _save() {
    final list = tenants.map((t) => t.toJson()).toList();
    _storage.write(_storageKey, list);
    final propId = activePropertyId;
    if (propId != null) {
      _storage.write("OWNER_TENANTS_$propId", list);
    }
    _storage.write("GLOBAL_ALL_TENANTS", list);
    _syncToDashboard();
  }

  /// Canonical floor key identifier for exact language-agnostic matching
  /// Returns "FLOOR_G", "FLOOR_1", "FLOOR_2", etc.
  static String getCanonicalFloorKey(String? rawFloor) {
    if (rawFloor == null || rawFloor.trim().isEmpty) return "";
    final lower = rawFloor.trim().toLowerCase();

    // Check Ground floor
    if (lower.contains("ផ្ទាល់ដី") || lower.contains("ground")) {
      return "FLOOR_G";
    }

    // Convert Khmer digits to Arabic digits
    final khmerDigits = {'១': '1', '២': '2', '៣': '3', '៤': '4', '៥': '5', '៦': '6', '៧': '7', '៨': '8', '៩': '9', '០': '0'};
    String norm = lower;
    khmerDigits.forEach((k, v) => norm = norm.replaceAll(k, v));

    final match = RegExp(r'\d+').firstMatch(norm);
    if (match != null) {
      return "FLOOR_${match.group(0)}";
    }

    return "CUSTOM_$lower";
  }

  /// Maps integer room floor level (where 1=Ground, 2=Floor 1, 3=Floor 2) to canonical floor key
  static String getRoomFloorCanonicalKey(int? floorNum) {
    if (floorNum == null || floorNum <= 0) return "";
    if (floorNum == 1) return "FLOOR_G";
    return "FLOOR_${floorNum - 1}";
  }

  /// Formats any floor string or canonical key into the active application language
  static String formatFloorDisplayName(String rawFloor) {
    final key = getCanonicalFloorKey(rawFloor);
    if (key == "FLOOR_G") {
      return LanguageService.isKhmer ? "ជាន់ផ្ទាល់ដី" : "Ground Floor";
    }
    if (key.startsWith("FLOOR_")) {
      final numStr = key.substring(6);
      if (LanguageService.isKhmer) {
        final khmerDigits = {'1': '១', '2': '២', '3': '៣', '4': '៤', '5': '៥', '6': '៦', '7': '៧', '8': '៨', '9': '៩', '0': '០'};
        final khmerNum = khmerDigits[numStr] ?? numStr;
        return "ជាន់ទី $khmerNum";
      } else {
        return "Floor $numStr";
      }
    }
    if (rawFloor.trim().isEmpty) {
      return LanguageService.isKhmer ? "ជាន់ទូទៅ" : "General Floor";
    }
    return rawFloor.trim();
  }

  bool matchesFloor(TenantModel t, String filter) {
    if (filter == "ALL") return true;

    final filterKey = getCanonicalFloorKey(filter);
    if (filterKey.isEmpty) return true;

    // 1. Direct canonical match from tenant.floor
    final tenantKey = getCanonicalFloorKey(t.floor);
    if (tenantKey.isNotEmpty) {
      return tenantKey == filterKey;
    }

    // 2. Room lookup fallback if tenant.floor was not set or empty
    if (Get.isRegistered<OwnerRoomsController>()) {
      final roomsCtrl = Get.find<OwnerRoomsController>();
      final cleanRoom = (t.roomNumber ?? '').trim().toLowerCase();
      final room = roomsCtrl.rooms.firstWhereOrNull(
        (r) => (r.roomNumber ?? '').trim().toLowerCase() == cleanRoom,
      );
      if (room != null && room.floor != null) {
        final roomKey = getRoomFloorCanonicalKey(room.floor);
        return roomKey == filterKey;
      }
    }

    return false;
  }

  List<String> get availableFloorNames {
    final canonicalKeys = <String>{};

    // 1. From OwnerFloorsController (the authoritative source of truth for floors)
    if (Get.isRegistered<OwnerFloorsController>()) {
      final fCtrl = Get.find<OwnerFloorsController>();
      for (final f in fCtrl.floors) {
        final key = getCanonicalFloorKey(f.name);
        if (key.isNotEmpty) {
          canonicalKeys.add(key);
        }
      }
    }

    // 2. If no registered floors exist in controller, derive from registered rooms
    if (canonicalKeys.isEmpty && Get.isRegistered<OwnerRoomsController>()) {
      final rCtrl = Get.find<OwnerRoomsController>();
      for (final r in rCtrl.rooms) {
        if (r.floor != null) {
          final key = getRoomFloorCanonicalKey(r.floor);
          if (key.isNotEmpty) {
            canonicalKeys.add(key);
          }
        }
      }
    }

    // 3. If still empty, derive from current tenants
    if (canonicalKeys.isEmpty) {
      for (final t in tenants) {
        final key = getCanonicalFloorKey(t.floor);
        if (key.isNotEmpty) {
          canonicalKeys.add(key);
        }
      }
    }

    // 4. Default fallback if property has no floor records
    if (canonicalKeys.isEmpty) {
      canonicalKeys.addAll(["FLOOR_G", "FLOOR_1", "FLOOR_2"]);
    }

    // Sort canonical keys in natural building order: FLOOR_G (0), FLOOR_1 (1), FLOOR_2 (2)...
    final sortedKeys = canonicalKeys.toList()
      ..sort((a, b) {
        int orderOf(String k) {
          if (k == "FLOOR_G") return 0;
          if (k.startsWith("FLOOR_")) {
            return int.tryParse(k.substring(6)) ?? 50;
          }
          return 100;
        }
        return orderOf(a).compareTo(orderOf(b));
      });

    // Convert canonical keys to localized display names for the active language
    return sortedKeys.map((k) => formatFloorDisplayName(k)).toList();
  }

  int getTenantCountForFloor(String floorFilter) {
    if (floorFilter == "ALL") return tenants.length;
    return tenants.where((t) => matchesFloor(t, floorFilter)).length;
  }

  List<TenantModel> get filteredTenants {
    final q = searchQuery.value.trim().toLowerCase();
    final filter = selectedFloorFilter.value;

    return tenants.where((t) {
      if (q.isNotEmpty) {
        final name = (t.name ?? '').toLowerCase();
        final phone = (t.phoneNumber ?? '').toLowerCase();
        final room = (t.roomNumber ?? '').toLowerCase();
        final floor = (t.floor ?? '').toLowerCase();
        final matchesQuery = name.contains(q) || phone.contains(q) || room.contains(q) || floor.contains(q);
        if (!matchesQuery) return false;
      }

      return matchesFloor(t, filter);
    }).toList();
  }

  Map<String, List<TenantModel>> get filteredTenantsByFloor {
    final map = <String, List<TenantModel>>{};
    final list = filteredTenants;

    for (final t in list) {
      String floorName = (t.floor ?? '').trim();
      if (floorName.isEmpty && t.roomNumber != null && Get.isRegistered<OwnerRoomsController>()) {
        final r = Get.find<OwnerRoomsController>().rooms.firstWhereOrNull(
            (rm) => (rm.roomNumber ?? '').trim().toLowerCase() == (t.roomNumber ?? '').trim().toLowerCase());
        if (r != null && r.floor != null) {
          final rKey = getRoomFloorCanonicalKey(r.floor);
          floorName = formatFloorDisplayName(rKey);
        }
      } else if (floorName.isNotEmpty) {
        floorName = formatFloorDisplayName(floorName);
      }

      if (floorName.isEmpty) {
        floorName = LanguageService.isKhmer ? "ជាន់ទូទៅ" : "General Floor";
      }
      map.putIfAbsent(floorName, () => []).add(t);
    }
    return map;
  }

  void addTenant({
    required String name,
    required String roomNumber,
    required String floor,
    required String phone,
    String? email,
  }) {
    final newId = tenants.isEmpty ? 1 : (tenants.map((t) => t.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
    final newTenant = TenantModel(
      id: newId,
      propertyId: activePropertyId,
      name: name,
      roomNumber: roomNumber,
      floor: floor,
      phoneNumber: phone,
      email: email ?? '',
      status: "ACTIVE",
    );
    tenants.insert(0, newTenant);
    _save();
  }

  void updateTenant({
    required int id,
    required String name,
    required String roomNumber,
    required String floor,
    required String phone,
    String? email,
  }) {
    final idx = tenants.indexWhere((t) => t.id == id);
    if (idx != -1) {
      tenants[idx] = TenantModel(
        id: id,
        propertyId: tenants[idx].propertyId ?? activePropertyId,
        name: name,
        roomNumber: roomNumber,
        floor: floor,
        phoneNumber: phone,
        email: email ?? tenants[idx].email ?? '',
        status: tenants[idx].status ?? 'ACTIVE',
        joinedDate: tenants[idx].joinedDate,
      );
      _save();
    }
  }

  bool isRoomOccupied(String roomNumber, {int? excludeTenantId}) {
    final cleanRoom = roomNumber.trim().toLowerCase();
    if (cleanRoom.isEmpty) return false;

    // 1. Check if another tenant already occupies this room
    final hasTenant = tenants.any((t) =>
        t.id != excludeTenantId &&
        (t.roomNumber ?? '').trim().toLowerCase() == cleanRoom);
    if (hasTenant) return true;

    // 2. Check if marked unavailable in OwnerRoomsController
    if (Get.isRegistered<OwnerRoomsController>()) {
      final roomsCtrl = Get.find<OwnerRoomsController>();
      final matchingRoom = roomsCtrl.rooms.firstWhereOrNull(
          (r) => (r.roomNumber ?? '').trim().toLowerCase() == cleanRoom);
      if (matchingRoom != null && (matchingRoom.available == false)) {
        return true;
      }
    }

    return false;
  }

  void removeTenant(int? id) {
    if (id == null) return;
    tenants.removeWhere((t) => t.id == id);
    _save();
  }
}
