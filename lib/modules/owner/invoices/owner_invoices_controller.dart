import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../models/rental/invoice_model.dart';
import '../../../core/services/api_service.dart';

class OwnerInvoicesController extends GetxController {
  final ApiService? apiService;
  final _storage = GetStorage();
  static const String _storageKey = "OWNER_INVOICES_PERSIST_KEY";

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
      final stored = _storage.read(_storageKey);
      if (stored is List && stored.isNotEmpty) {
        invoices.value = stored
            .map((item) => InvoiceModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } else {
        invoices.value = [
          InvoiceModel(
            id: 1,
            invoiceNo: "INV-CF043A",
            propertyName: "My Home",
            tenantName: "តុលា សុខ",
            roomNumber: "00001",
            floor: "ជាន់ទី១",
            issueDate: "Apr 8, 2026",
            dueDate: "Apr 9, 2026",
            rentAmount: 50.00,
            electricityUnits: 1.0,
            electricityRate: 0.12,
            waterUnits: 1.0,
            waterRate: 1.50,
            totalAmount: 51.62,
            status: "UNPAID",
          ),
          InvoiceModel(
            id: 2,
            invoiceNo: "INV-CF042B",
            propertyName: "My Home",
            tenantName: "តុលា សុខ",
            roomNumber: "00001",
            floor: "ជាន់ទី១",
            issueDate: "Apr 7, 2026",
            dueDate: "Apr 8, 2026",
            rentAmount: 50.00,
            electricityUnits: 0.0,
            electricityRate: 0.12,
            waterUnits: 0.0,
            waterRate: 1.50,
            totalAmount: 50.00,
            status: "PAID",
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
    _storage.write(_storageKey, invoices.map((inv) => inv.toJson()).toList());
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
