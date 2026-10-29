import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../models/rental/invoice_model.dart';
import '../../../models/rental/tenant_model.dart';
import '../../../models/rental/room_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/language_service.dart';
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

  static String formatIssueDate([DateTime? date]) {
    final d = date ?? DateTime.now();
    if (LanguageService.isKhmer) {
      final khmerMonths = ['មករា', 'កុម្ភៈ', 'មីនា', 'មេសា', 'ឧសភា', 'មិថុនា', 'កក្កដា', 'សីហា', 'កញ្ញា', 'តុលា', 'វិច្ឆិកា', 'ធ្នូ'];
      return "${d.day} ${khmerMonths[d.month - 1]} ${d.year}";
    }
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${months[d.month - 1]} ${d.day}, ${d.year}";
  }

  static String formatDueDate([DateTime? date, int daysLater = 7]) {
    final d = date != null ? date.add(Duration(days: daysLater)) : DateTime.now().add(Duration(days: daysLater));
    if (LanguageService.isKhmer) {
      final khmerMonths = ['មករា', 'កុម្ភៈ', 'មីនា', 'មេសា', 'ឧសភា', 'មិថុនា', 'កក្កដា', 'សីហា', 'កញ្ញា', 'តុលា', 'វិច្ឆិកា', 'ធ្នូ'];
      return "${d.day} ${khmerMonths[d.month - 1]} ${d.year}";
    }
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${months[d.month - 1]} ${d.day}, ${d.year}";
  }

  InvoiceModel generateMoveInInvoice({
    required TenantModel tenant,
    required double rentAmount,
    String? propertyName,
  }) {
    final now = DateTime.now();
    final cleanRoom = (tenant.roomNumber ?? 'Room').replaceAll(' ', '');
    final invNo = "INV-${now.year}${now.month.toString().padLeft(2, '0')}-$cleanRoom";
    final effectivePropName = propertyName ??
        (Get.isRegistered<OwnerMainController>()
            ? Get.find<OwnerMainController>().selectedPropertyName.value
            : "My Property");

    final newInv = InvoiceModel(
      id: DateTime.now().millisecondsSinceEpoch,
      invoiceNo: invNo,
      propertyName: effectivePropName,
      tenantName: tenant.name ?? "Tenant",
      roomNumber: tenant.roomNumber ?? "",
      floor: tenant.floor ?? "Ground Floor",
      issueDate: formatIssueDate(now),
      dueDate: formatDueDate(now, 7),
      rentAmount: rentAmount,
      electricityUnits: 0.0,
      electricityRate: 0.25,
      waterUnits: 0.0,
      waterRate: 0.35,
      garbageFee: 2.0,
      totalAmount: rentAmount + 2.0,
      status: "UNPAID",
    );

    createInvoice(newInv);
    return newInv;
  }

  int generateMonthlyInvoices({
    required List<TenantModel> activeTenants,
    required List<RoomModel> allRooms,
    String? propertyName,
    DateTime? monthTarget,
    int dueDaysLater = 7,
  }) {
    final now = monthTarget ?? DateTime.now();
    final monthStr = now.month.toString().padLeft(2, '0');
    final yearStr = now.year.toString();
    final effectivePropName = propertyName ??
        (Get.isRegistered<OwnerMainController>()
            ? Get.find<OwnerMainController>().selectedPropertyName.value
            : "My Property");

    int createdCount = 0;

    for (final tenant in activeTenants) {
      final tName = (tenant.name ?? '').trim();
      final rNum = (tenant.roomNumber ?? '').trim();
      if (tName.isEmpty || rNum.isEmpty) continue;

      // Check if already invoiced in this month for this room
      final alreadyInvoiced = invoices.any((inv) {
        final sameRoom = (inv.roomNumber ?? '').trim().toLowerCase() == rNum.toLowerCase();
        final sameTenant = (inv.tenantName ?? '').trim().toLowerCase() == tName.toLowerCase();
        final invNo = inv.invoiceNo ?? '';
        final sameMonthYear = invNo.contains("INV-$yearStr$monthStr");
        return sameRoom && sameTenant && sameMonthYear;
      });

      if (alreadyInvoiced) continue;

      final matchingRoom = allRooms.firstWhereOrNull(
          (r) => (r.roomNumber ?? '').trim().toLowerCase() == rNum.toLowerCase());
      final rent = matchingRoom?.price ?? 50.0;
      final garbage = 2.0;
      final total = rent + garbage;

      final inv = InvoiceModel(
        id: DateTime.now().millisecondsSinceEpoch + createdCount,
        invoiceNo: "INV-$yearStr$monthStr-${rNum.replaceAll(' ', '')}",
        propertyName: effectivePropName,
        tenantName: tName,
        roomNumber: rNum,
        floor: tenant.floor ?? (matchingRoom?.floor != null ? "ជាន់ទី ${matchingRoom!.floor}" : "ជាន់ផ្ទាល់ដី"),
        issueDate: formatIssueDate(now),
        dueDate: formatDueDate(now, dueDaysLater),
        rentAmount: rent,
        electricityUnits: 0.0,
        electricityRate: 0.25,
        waterUnits: 0.0,
        waterRate: 0.35,
        garbageFee: garbage,
        totalAmount: total,
        status: "UNPAID",
      );

      invoices.insert(0, inv);
      createdCount++;
    }

    if (createdCount > 0) {
      _save();
    }

    return createdCount;
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
