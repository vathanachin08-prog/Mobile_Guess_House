import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../models/rental/invoice_model.dart';
import '../../../core/services/api_service.dart';
import '../../../data/local/token_store_local.dart';
import '../owner_main_controller.dart';
import '../dashboard/owner_dashboard_controller.dart';

class OwnerInvoicesController extends GetxController {
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
    return TokenStoreLocal.getUserScopedKey("OWNER_INVOICES_${propId ?? 'none'}");
  }

  String get _legacyStorageKey => TokenStoreLocal.getUserScopedKey("OWNER_INVOICES_PERSIST_KEY");

  OwnerInvoicesController({this.apiService});

  final invoices = <InvoiceModel>[].obs;
  final selectedFilter = "ALL".obs; // ALL, UNPAID, PAID
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadInvoices();
  }

  void loadInvoices() {
    isLoading.value = true;
    try {
      var stored = _storage.read(_storageKey);
      if (stored == null || (stored is List && stored.isEmpty)) {
        final legacyStored = _storage.read(_legacyStorageKey);
        if (legacyStored is List && legacyStored.isNotEmpty) {
          stored = legacyStored;
          _storage.write(_storageKey, stored);
          _storage.remove(_legacyStorageKey);
        }
      }
      if (stored is List && stored.isNotEmpty) {
        invoices.value = stored
            .map((item) => InvoiceModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } else {
        invoices.clear();
      }
    } catch (_) {
      invoices.clear();
    } finally {
      isLoading.value = false;
      _syncToDashboard();
    }
  }

  void _syncToDashboard() {
    if (Get.isRegistered<OwnerDashboardController>()) {
      final dashCtrl = Get.find<OwnerDashboardController>();
      if (dashCtrl.currentProperty.value?.id == activePropertyId) {
        dashCtrl.unpaidInvoices.value = unpaidCount;
        dashCtrl.totalRevenue.value = totalCollectedRevenue;
        dashCtrl.expectedRevenue.value = totalExpectedRevenue;
      }
    }
  }

  void _save() {
    _storage.write(_storageKey, invoices.map((inv) => inv.toJson()).toList());
    _syncToDashboard();
  }

  List<InvoiceModel> get filteredInvoices {
    if (selectedFilter.value == "ALL") return invoices;
    return invoices.where((i) => (i.status ?? '').toUpperCase() == selectedFilter.value).toList();
  }

  // Dynamic calculated stats
  double get totalExpectedRevenue {
    return invoices.fold(0.0, (sum, i) => sum + (i.totalAmount ?? 0.0));
  }

  double get totalCollectedRevenue {
    return invoices
        .where((i) => (i.status ?? '').toUpperCase() == "PAID")
        .fold(0.0, (sum, i) => sum + (i.totalAmount ?? 0.0));
  }

  int get unpaidCount {
    return invoices.where((i) => (i.status ?? '').toUpperCase() == "UNPAID").length;
  }

  int get overdueCount {
    return invoices.where((i) => (i.status ?? '').toUpperCase() == "OVERDUE").length;
  }

  void markAsPaid(int? id) {
    if (id == null) return;
    final idx = invoices.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final old = invoices[idx];
      invoices[idx] = InvoiceModel(
        id: old.id,
        invoiceNo: old.invoiceNo,
        propertyName: old.propertyName,
        tenantName: old.tenantName,
        roomNumber: old.roomNumber,
        floor: old.floor,
        issueDate: old.issueDate,
        dueDate: old.dueDate,
        rentAmount: old.rentAmount,
        electricityUnits: old.electricityUnits,
        electricityRate: old.electricityRate,
        waterUnits: old.waterUnits,
        waterRate: old.waterRate,
        totalAmount: old.totalAmount,
        status: "PAID",
      );
      _save();
    }
  }

  void markAsUnpaid(int? id) {
    if (id == null) return;
    final idx = invoices.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final old = invoices[idx];
      invoices[idx] = InvoiceModel(
        id: old.id,
        invoiceNo: old.invoiceNo,
        propertyName: old.propertyName,
        tenantName: old.tenantName,
        roomNumber: old.roomNumber,
        floor: old.floor,
        issueDate: old.issueDate,
        dueDate: old.dueDate,
        rentAmount: old.rentAmount,
        electricityUnits: old.electricityUnits,
        electricityRate: old.electricityRate,
        waterUnits: old.waterUnits,
        waterRate: old.waterRate,
        totalAmount: old.totalAmount,
        status: "UNPAID",
      );
      _save();
    }
  }

  void createInvoice(InvoiceModel inv) {
    invoices.insert(0, inv);
    _save();
  }

  void deleteInvoice(int? id) {
    if (id == null) return;
    invoices.removeWhere((i) => i.id == id);
    _save();
  }
}
