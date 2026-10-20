import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../models/rental/tenant_model.dart';
import '../../../core/services/api_service.dart';
import '../../../data/local/token_store_local.dart';
import '../owner_main_controller.dart';
import '../dashboard/owner_dashboard_controller.dart';

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
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadTenants();
  }

  void loadTenants() {
    isLoading.value = true;
    try {
      final propId = activePropertyId;
      var stored = _storage.read(_storageKey);

      // Check migration from legacy key if current property storage is empty
      if (stored == null || (stored is List && stored.isEmpty)) {
        final legacyStored = _storage.read(_legacyStorageKey);
        if (legacyStored is List && legacyStored.isNotEmpty) {
          // Migrate legacy tenants to the active property
          final migrated = legacyStored.map((item) {
            final map = Map<String, dynamic>.from(item);
            if (map['propertyId'] == null && propId != null) {
              map['propertyId'] = propId;
            }
            return map;
          }).toList();
          _storage.write(_storageKey, migrated);
          // Remove legacy key so other properties don't inherit these tenants
          _storage.remove(_legacyStorageKey);
          stored = migrated;
        }
      }

      if (stored is List && stored.isNotEmpty) {
        tenants.value = stored
            .map((item) => TenantModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } else {
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
    _storage.write(_storageKey, tenants.map((t) => t.toJson()).toList());
    _syncToDashboard();
  }

  List<TenantModel> get filteredTenants {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return tenants;
    return tenants.where((t) {
      final name = (t.name ?? '').toLowerCase();
      final phone = (t.phoneNumber ?? '').toLowerCase();
      final room = (t.roomNumber ?? '').toLowerCase();
      return name.contains(q) || phone.contains(q) || room.contains(q);
    }).toList();
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

  void removeTenant(int? id) {
    if (id == null) return;
    tenants.removeWhere((t) => t.id == id);
    _save();
  }
}
