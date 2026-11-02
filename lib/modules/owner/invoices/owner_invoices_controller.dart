import 'package:flutter/material.dart';
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
import '../../student/home/student_home_controller.dart';

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
  final selectedDateFilterType = "ALL".obs; // ALL, TODAY, THIS_MONTH, LAST_MONTH, CUSTOM_DATE, CUSTOM_RANGE
  final selectedCustomDate = Rxn<DateTime>();
  final selectedCustomRange = Rxn<DateTimeRange>();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadInvoices();

    // Re-load invoices whenever active property is selected or finishes loading
    if (Get.isRegistered<OwnerMainController>()) {
      ever(Get.find<OwnerMainController>().selectedPropertyId, (_) {
        loadInvoices();
      });
    }
  }

  void loadInvoices() {
    isLoading.value = true;
    try {
      final propId = activePropertyId;
      dynamic stored;

      // Check all possible persistent storage keys in cascade
      final candidateKeys = [
        _storageKey,
        TokenStoreLocal.getUserScopedKey("OWNER_INVOICES_${propId ?? ''}"),
        "OWNER_INVOICES_${propId ?? 'none'}",
        "OWNER_INVOICES_${propId ?? ''}",
        "GLOBAL_ALL_INVOICES",
        _legacyStorageKey,
        TokenStoreLocal.getUserScopedKey("OWNER_INVOICES_PERSIST_KEY"),
        "OWNER_INVOICES_PERSIST_KEY",
        "OWNER_INVOICES_none",
        "OWNER_INVOICES_PERSIST_KEY_default",
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
            .map((item) => InvoiceModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        invoices.value = loaded;
      } else {
        // Purely dynamic: empty if no invoices generated yet
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
    final list = invoices.map((inv) => inv.toJson()).toList();
    _storage.write(_storageKey, list);
    final propId = activePropertyId;
    if (propId != null) {
      _storage.write("OWNER_INVOICES_$propId", list);
    }
    _storage.write("GLOBAL_ALL_INVOICES", list);
    _syncToDashboard();
  }

  bool get isDateFilterActive => selectedDateFilterType.value != "ALL";

  void setDateFilterType(String type) {
    selectedDateFilterType.value = type;
  }

  void setCustomDate(DateTime date) {
    selectedCustomDate.value = date;
    selectedDateFilterType.value = "CUSTOM_DATE";
  }

  void setCustomDateRange(DateTimeRange range) {
    selectedCustomRange.value = range;
    selectedDateFilterType.value = "CUSTOM_RANGE";
  }

  void clearDateFilter() {
    selectedDateFilterType.value = "ALL";
    selectedCustomDate.value = null;
    selectedCustomRange.value = null;
  }

  String get dateFilterLabel {
    final type = selectedDateFilterType.value;
    final isKh = LanguageService.isKhmer;

    switch (type) {
      case "TODAY":
        return isKh ? "ថ្ងៃនេះ" : "Today";
      case "THIS_MONTH":
        return isKh ? "ខែនេះ" : "This Month";
      case "LAST_MONTH":
        return isKh ? "ខែមុន" : "Last Month";
      case "CUSTOM_DATE":
        final d = selectedCustomDate.value;
        if (d != null) {
          if (isKh) {
            final khmerMonths = ['មករា', 'កុម្ភៈ', 'មីនា', 'មេសា', 'ឧសភា', 'មិថុនា', 'កក្កដា', 'សីហា', 'កញ្ញា', 'តុលា', 'វិច្ឆិកា', 'ធ្នូ'];
            return "${d.day} ${khmerMonths[d.month - 1]}";
          }
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return "${months[d.month - 1]} ${d.day}";
        }
        return isKh ? "ថ្ងៃជាក់លាក់" : "Date";
      case "CUSTOM_RANGE":
        final r = selectedCustomRange.value;
        if (r != null) {
          return "${r.start.day}/${r.start.month} - ${r.end.day}/${r.end.month}";
        }
        return isKh ? "ចន្លោះកាលបរិច្ឆេទ" : "Range";
      case "ALL":
      default:
        return isKh ? "កាលបរិច្ឆេទ" : "Date";
    }
  }

  bool matchesDate(InvoiceModel inv) {
    final type = selectedDateFilterType.value;
    if (type == "ALL") return true;

    final date = inv.parsedIssueDate;
    if (date == null) return true;

    final now = DateTime.now();

    if (type == "TODAY") {
      return date.year == now.year && date.month == now.month && date.day == now.day;
    }

    if (type == "THIS_MONTH") {
      return date.year == now.year && date.month == now.month;
    }

    if (type == "LAST_MONTH") {
      final prevMonthTarget = DateTime(now.year, now.month - 1, 1);
      return date.year == prevMonthTarget.year && date.month == prevMonthTarget.month;
    }

    if (type == "CUSTOM_DATE") {
      final target = selectedCustomDate.value;
      if (target == null) return true;
      return date.year == target.year && date.month == target.month && date.day == target.day;
    }

    if (type == "CUSTOM_RANGE") {
      final range = selectedCustomRange.value;
      if (range == null) return true;
      final start = DateTime(range.start.year, range.start.month, range.start.day);
      final end = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
      return (date.isAfter(start) || date.isAtSameMomentAs(start)) &&
             (date.isBefore(end) || date.isAtSameMomentAs(end));
    }

    return true;
  }

  int getInvoiceCountForDateFilter(String type) {
    if (type == "ALL") return invoices.length;
    final now = DateTime.now();
    return invoices.where((inv) {
      final date = inv.parsedIssueDate;
      if (date == null) return false;
      if (type == "TODAY") {
        return date.year == now.year && date.month == now.month && date.day == now.day;
      }
      if (type == "THIS_MONTH") {
        return date.year == now.year && date.month == now.month;
      }
      if (type == "LAST_MONTH") {
        final prev = DateTime(now.year, now.month - 1, 1);
        return date.year == prev.year && date.month == prev.month;
      }
      return true;
    }).length;
  }

  List<InvoiceModel> get dateFilteredInvoices {
    if (selectedDateFilterType.value == "ALL") return invoices;
    return invoices.where(matchesDate).toList();
  }

  List<InvoiceModel> get filteredInvoices {
    return invoices.where((i) {
      if (selectedFilter.value != "ALL") {
        if ((i.status ?? '').toUpperCase() != selectedFilter.value) {
          return false;
        }
      }
      return matchesDate(i);
    }).toList();
  }

  // Dynamic calculated stats based on active date filter
  double get totalExpectedRevenue {
    final list = dateFilteredInvoices;
    return list.fold(0.0, (sum, i) => sum + (i.totalAmount ?? 0.0));
  }

  double get totalCollectedRevenue {
    final list = dateFilteredInvoices;
    return list
        .where((i) => (i.status ?? '').toUpperCase() == "PAID")
        .fold(0.0, (sum, i) => sum + (i.totalAmount ?? 0.0));
  }

  int get unpaidCount {
    final list = dateFilteredInvoices;
    return list.where((i) => (i.status ?? '').toUpperCase() == "UNPAID").length;
  }

  int get overdueCount {
    final list = dateFilteredInvoices;
    return list.where((i) => (i.status ?? '').toUpperCase() == "OVERDUE").length;
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

  /// Sends an in-app payment alert notification to the tenant
  void alertTenantForInvoice(InvoiceModel inv) {
    StudentHomeController.addInvoiceAlertNotification(
      invoiceNo: inv.invoiceNo ?? "INV",
      tenantName: inv.tenantName ?? "Tenant",
      roomNumber: inv.roomNumber ?? "",
      totalAmount: inv.totalAmount ?? 0.0,
      dueDate: inv.dueDate,
    );
  }

  /// Sends payment alerts to all tenants with unpaid or overdue invoices
  int alertAllUnpaidTenants() {
    final unpaid = invoices.where((i) => i.isUnpaid || i.isOverdue).toList();
    for (final inv in unpaid) {
      alertTenantForInvoice(inv);
    }
    return unpaid.length;
  }
}
