import 'dart:convert';
import 'package:get/get.dart';
import '../../../constants/constant_uri.dart';
import '../../../core/services/api_service.dart';
import '../../../data/local/token_store_local.dart';
import '../../../models/rental/property_model.dart';
import '../floors/owner_floors_controller.dart';
import '../rooms/owner_rooms_controller.dart';
import '../tenants/owner_tenants_controller.dart';
import '../invoices/owner_invoices_controller.dart';

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

  final user = Rxn<Map<String, dynamic>>();
  final ownerNameRx = "Owner".obs;

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
        return;
      }
      final un = u['username'];
      if (un != null && un.toString().isNotEmpty) {
        ownerNameRx.value = un.toString();
        return;
      }
    }
    ownerNameRx.value = 'Owner';
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
        if (decoded['data'] != null && decoded['data'] is List) {
          final List list = decoded['data'];
          final props = list.map((e) => PropertyModel.fromJson(e)).toList();
          myProperties.assignAll(props);
          if (myProperties.isNotEmpty) {
            currentProperty.value = myProperties.first;
            if (currentProperty.value?.rooms != null) {
              final rList = currentProperty.value!.rooms!;
              totalRooms.value = rList.length;
              availableRooms.value = rList.where((r) => r.available == true).length;
              occupiedRooms.value = rList.where((r) => r.available == false).length;
            }
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
      totalFloors.value = fCtrl.floors.length;
    }
    if (Get.isRegistered<OwnerRoomsController>()) {
      final rCtrl = Get.find<OwnerRoomsController>();
      totalRooms.value = rCtrl.rooms.length;
      availableRooms.value = rCtrl.rooms.where((r) => r.available == true).length;
      occupiedRooms.value = rCtrl.rooms.where((r) => r.available == false).length;
    }
    if (Get.isRegistered<OwnerTenantsController>()) {
      final tCtrl = Get.find<OwnerTenantsController>();
      totalTenants.value = tCtrl.tenants.length;
    }
    if (Get.isRegistered<OwnerInvoicesController>()) {
      final iCtrl = Get.find<OwnerInvoicesController>();
      unpaidInvoices.value = iCtrl.unpaidCount;
      totalRevenue.value = iCtrl.totalCollectedRevenue;
      expectedRevenue.value = iCtrl.totalExpectedRevenue;
    }
  }

  void switchProperty(PropertyModel p) {
    currentProperty.value = p;
  }
}
