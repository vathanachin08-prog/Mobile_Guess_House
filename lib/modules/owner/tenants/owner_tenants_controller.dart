import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../models/rental/tenant_model.dart';
import '../../../core/services/api_service.dart';

class OwnerTenantsController extends GetxController {
  final ApiService? apiService;
  final _storage = GetStorage();
  static const String _storageKey = "OWNER_TENANTS_PERSIST_KEY";

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
      final stored = _storage.read(_storageKey);
      if (stored is List && stored.isNotEmpty) {
        tenants.value = stored
            .map((item) => TenantModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } else {
        // Initial real-like dataset matching reference
        tenants.value = [
          TenantModel(
            id: 1,
            name: "តុលា សុខ",
            roomNumber: "00001",
            floor: "ជាន់ទី១",
            email: "myhome+1@gmail.com",
            phoneNumber: "03423423423",
            status: "ACTIVE",
          ),
          TenantModel(
            id: 2,
            name: "សុខ រដ្ឋា",
            roomNumber: "00002",
            floor: "ជាន់ទី១",
            email: "rothasok@gmail.com",
            phoneNumber: "012889900",
            status: "ACTIVE",
          ),
        ];
        _save();
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  void _save() {
    _storage.write(_storageKey, tenants.map((t) => t.toJson()).toList());
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

  void removeTenant(int? id) {
    if (id == null) return;
    tenants.removeWhere((t) => t.id == id);
    _save();
  }
}
