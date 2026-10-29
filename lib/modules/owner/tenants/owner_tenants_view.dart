import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/language_service.dart';
import '../../../models/rental/tenant_model.dart';
import '../../../models/rental/invoice_model.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/custom_app_bar.dart';
import '../floors/owner_floors_controller.dart';
import '../rooms/owner_rooms_controller.dart';
import '../invoices/owner_invoices_controller.dart';
import '../owner_main_controller.dart';
import 'owner_tenants_controller.dart';

class _FloorOption {
  final int floorNumber;
  final String displayName;

  const _FloorOption({required this.floorNumber, required this.displayName});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _FloorOption &&
          runtimeType == other.runtimeType &&
          floorNumber == other.floorNumber;

  @override
  int get hashCode => floorNumber.hashCode;
}

class OwnerTenantsView extends StatefulWidget {
  final bool showAppBar;
  const OwnerTenantsView({super.key, this.showAppBar = false});

  @override
  State<OwnerTenantsView> createState() => _OwnerTenantsViewState();
}

class _OwnerTenantsViewState extends State<OwnerTenantsView> {
  final searchController = TextEditingController();
  late final OwnerTenantsController controller;
  final RxInt _visibleLimit = 5.obs;
  final RxBool _isLoadingMore = false.obs;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<OwnerTenantsController>()
        ? Get.find<OwnerTenantsController>()
        : Get.put(OwnerTenantsController());
    searchController.addListener(() {
      controller.searchQuery.value = searchController.text;
      _resetPagination();
    });
  }

  void _loadMore() {
    final total = controller.filteredTenants.length;
    if (_visibleLimit.value < total && !_isLoadingMore.value) {
      _isLoadingMore.value = true;
      Future.delayed(const Duration(milliseconds: 300), () {
        _visibleLimit.value = (_visibleLimit.value + 5).clamp(0, total);
        _isLoadingMore.value = false;
      });
    }
  }

  void _resetPagination() {
    _visibleLimit.value = 5;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String _formatFloorName(int fNum) {
    if (fNum == 1) {
      return LanguageService.isKhmer ? "ជាន់ផ្ទាល់ដី" : "Ground Floor";
    }
    final actualNum = fNum > 1 ? fNum - 1 : fNum;
    final khmerDigits = {'1': '១', '2': '២', '3': '៣', '4': '៤', '5': '៥', '6': '៦', '7': '៧', '8': '៨', '9': '៩', '0': '០'};
    String khmerNum = actualNum.toString();
    khmerDigits.forEach((k, v) => khmerNum = khmerNum.replaceAll(k, v));
    return LanguageService.isKhmer ? "ជាន់ទី $khmerNum" : "Floor $actualNum";
  }

  void _showActionSheet(TenantModel tenant) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('actions'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined, color: AppColors.accentOrange),
              title: Text('remove_from_room'.tr),
              onTap: () {
                final roomNum = tenant.roomNumber;
                controller.removeTenant(tenant.id);
                if (roomNum != null && Get.isRegistered<OwnerRoomsController>()) {
                  final hasOther = controller.tenants.any((t) =>
                      (t.roomNumber ?? '').trim().toLowerCase() == roomNum.trim().toLowerCase());
                  if (!hasOther) {
                    Get.find<OwnerRoomsController>().setRoomAvailability(roomNum, true);
                  }
                }
                Navigator.pop(ctx);
                Get.snackbar(
                  'notice'.tr,
                  "${tenant.name} • ${tenant.roomNumber}",
                  backgroundColor: Colors.white,
                  margin: const EdgeInsets.all(16),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
              title: Text('manage_invoice'.tr),
              onTap: () {
                Navigator.pop(ctx);
                _showTenantInvoicesSheet(tenant);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.accentBlue),
              title: Text('edit'.tr),
              onTap: () {
                Navigator.pop(ctx);
                _showAddTenantDialog(tenantToEdit: tenant);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              title: Text('delete'.tr, style: const TextStyle(color: AppColors.danger)),
              onTap: () {
                final roomNum = tenant.roomNumber;
                controller.removeTenant(tenant.id);
                if (roomNum != null && Get.isRegistered<OwnerRoomsController>()) {
                  final hasOther = controller.tenants.any((t) =>
                      (t.roomNumber ?? '').trim().toLowerCase() == roomNum.trim().toLowerCase());
                  if (!hasOther) {
                    Get.find<OwnerRoomsController>().setRoomAvailability(roomNum, true);
                  }
                }
                Navigator.pop(ctx);
                Get.snackbar('delete'.tr, "${tenant.name}", backgroundColor: Colors.white, margin: const EdgeInsets.all(16));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTenantInvoicesSheet(TenantModel tenant) {
    final invoicesCtrl = Get.isRegistered<OwnerInvoicesController>()
        ? Get.find<OwnerInvoicesController>()
        : Get.put(OwnerInvoicesController());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primarySoft,
                  child: Text(
                    (tenant.name != null && tenant.name!.isNotEmpty) ? tenant.name!.substring(0, 1) : "T",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenant.name ?? "Tenant",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                      ),
                      Text(
                        "${tenant.floor ?? ''} • ${'room_label_prefix'.tr} ${tenant.roomNumber ?? ''}",
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showCreateInvoiceForTenant(tenant);
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(
                    LanguageService.isKhmer ? "បង្កើតវិក្កយបត្រ" : "New Invoice",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.border),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                final tenantRoom = (tenant.roomNumber ?? '').trim().toLowerCase();
                final tenantName = (tenant.name ?? '').trim().toLowerCase();

                final tenantInvoices = invoicesCtrl.invoices.where((inv) {
                  final invRoom = (inv.roomNumber ?? '').trim().toLowerCase();
                  final invName = (inv.tenantName ?? '').trim().toLowerCase();
                  return (tenantRoom.isNotEmpty && invRoom == tenantRoom) ||
                      (tenantName.isNotEmpty && invName == tenantName);
                }).toList();

                if (tenantInvoices.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            LanguageService.isKhmer
                                ? "មិនទាន់មានវិក្កយបត្រសម្រាប់អ្នកជួលនេះទេ"
                                : "No invoices found for this tenant",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showCreateInvoiceForTenant(tenant);
                            },
                            icon: const Icon(Icons.flash_on_rounded, color: AppColors.primary, size: 18),
                            label: Text(
                              LanguageService.isKhmer ? "ចេញវិក្កយបត្រដំបូង" : "Generate First Invoice",
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: tenantInvoices.length,
                  itemBuilder: (context, index) {
                    final inv = tenantInvoices[index];
                    final isPaid = inv.isPaid;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPaid ? AppColors.primary.withOpacity(0.3) : AppColors.accentOrange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isPaid ? AppColors.primarySoft : AppColors.accentOrangeLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isPaid ? Icons.check_circle_outline_rounded : Icons.pending_actions_rounded,
                              color: isPaid ? AppColors.primary : AppColors.accentOrange,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      inv.invoiceNo ?? "INV",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                    ),
                                    const Spacer(),
                                    Text(
                                      "\$${(inv.totalAmount ?? 0.0).toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isPaid ? AppColors.primary : AppColors.accentOrange,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      inv.issueDate ?? '',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                    const Spacer(),
                                    InkWell(
                                      onTap: () {
                                        if (isPaid) {
                                          invoicesCtrl.markAsUnpaid(inv.id);
                                        } else {
                                          invoicesCtrl.markAsPaid(inv.id);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isPaid ? AppColors.primarySoft : AppColors.accentOrangeLight,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isPaid ? 'paid_status'.tr : 'unpaid_status'.tr,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isPaid ? AppColors.primary : AppColors.accentOrange,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () {
                                        _confirmDeleteInvoice(inv, invoicesCtrl);
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteInvoice(InvoiceModel inv, OwnerInvoicesController invoicesCtrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                LanguageService.isKhmer ? "លុបវិក្កយបត្រ" : "Delete Invoice",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          LanguageService.isKhmer
              ? "តើអ្នកពិតជាចង់លុបវិក្កយបត្រ ${inv.invoiceNo ?? ''} នេះមែនទេ?"
              : "Are you sure you want to delete invoice ${inv.invoiceNo ?? ''}?",
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              invoicesCtrl.deleteInvoice(inv.id);
              Navigator.pop(ctx);
              Get.snackbar(
                'delete'.tr,
                LanguageService.isKhmer
                    ? "បានលុបវិក្កយបត្រ ${inv.invoiceNo ?? ''} ដោយជោគជ័យ"
                    : "Invoice ${inv.invoiceNo ?? ''} deleted successfully",
                backgroundColor: Colors.white,
                margin: const EdgeInsets.all(16),
                icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.danger),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              LanguageService.isKhmer ? "លុប" : "Delete",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateInvoiceForTenant(TenantModel tenant) {
    final roomsCtrl = Get.isRegistered<OwnerRoomsController>()
        ? Get.find<OwnerRoomsController>()
        : Get.put(OwnerRoomsController());
    final invoicesCtrl = Get.isRegistered<OwnerInvoicesController>()
        ? Get.find<OwnerInvoicesController>()
        : Get.put(OwnerInvoicesController());

    final propName = Get.isRegistered<OwnerMainController>()
        ? Get.find<OwnerMainController>().selectedPropertyName.value
        : "My Property";

    final roomNum = tenant.roomNumber ?? "";
    final matchingRoom = roomsCtrl.rooms.firstWhereOrNull((r) =>
        (r.roomNumber ?? '').trim().toLowerCase() == roomNum.trim().toLowerCase());
    final defaultRent = matchingRoom?.price ?? 50.0;

    final nameCtrl = TextEditingController(text: tenant.name ?? '');
    final roomCtrl = TextEditingController(text: roomNum);
    final rentCtrl = TextEditingController(text: defaultRent.toStringAsFixed(2));
    final elecCtrl = TextEditingController(text: "0.0");
    final waterCtrl = TextEditingController(text: "0.0");
    final garbageCtrl = TextEditingController(text: "2.00");

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    LanguageService.isKhmer ? "ចេញវិក្កយបត្រថ្មី" : "Create New Invoice",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'tenant_label'.tr,
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: roomCtrl,
                    decoration: InputDecoration(
                      labelText: 'room_number'.tr,
                      prefixIcon: const Icon(Icons.meeting_room_outlined, color: AppColors.primary, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: rentCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'rent_price_label'.tr,
                      prefixIcon: const Icon(Icons.attach_money, color: AppColors.primary, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: elecCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: LanguageService.isKhmer ? "ភ្លើង kWh" : "Elec kWh",
                            prefixIcon: const Icon(Icons.bolt, color: AppColors.primary, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: waterCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: LanguageService.isKhmer ? "ទឹក m³" : "Water m³",
                            prefixIcon: const Icon(Icons.water_drop_outlined, color: AppColors.primary, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: garbageCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: LanguageService.isKhmer ? "ថ្លៃសំរាម" : "Garbage Fee",
                      prefixIcon: const Icon(Icons.delete_outline, color: AppColors.primary, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('cancel'.tr, style: const TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () {
                  final tName = nameCtrl.text.trim();
                  final rNum = roomCtrl.text.trim();
                  if (tName.isEmpty || rNum.isEmpty) {
                    Get.snackbar(
                      'error'.tr,
                      LanguageService.isKhmer ? "សូមបញ្ចូលឈ្មោះ និងលេខបន្ទប់" : "Please enter name and room",
                      backgroundColor: Colors.red.shade50,
                    );
                    return;
                  }

                  final rent = double.tryParse(rentCtrl.text.trim()) ?? defaultRent;
                  final elec = double.tryParse(elecCtrl.text.trim()) ?? 0.0;
                  final water = double.tryParse(waterCtrl.text.trim()) ?? 0.0;
                  final garbage = double.tryParse(garbageCtrl.text.trim()) ?? 2.0;
                  final total = rent + (elec * 0.25) + (water * 0.35) + garbage;

                  final now = DateTime.now();
                  final cleanRoom = rNum.replaceAll(' ', '');
                  final invNo = "INV-${now.year}${now.month.toString().padLeft(2, '0')}-$cleanRoom";

                  final inv = InvoiceModel(
                    id: DateTime.now().millisecondsSinceEpoch,
                    invoiceNo: invNo,
                    propertyName: propName,
                    tenantName: tName,
                    roomNumber: rNum,
                    floor: tenant.floor ?? "Ground Floor",
                    issueDate: OwnerInvoicesController.formatIssueDate(now),
                    dueDate: OwnerInvoicesController.formatDueDate(now, 7),
                    rentAmount: rent,
                    electricityUnits: elec,
                    electricityRate: 0.25,
                    waterUnits: water,
                    waterRate: 0.35,
                    garbageFee: garbage,
                    totalAmount: total,
                    status: "UNPAID",
                  );

                  invoicesCtrl.createInvoice(inv);
                  Navigator.pop(ctx);
                  Get.snackbar(
                    'success'.tr,
                    "${inv.invoiceNo} • \$${total.toStringAsFixed(2)}",
                    backgroundColor: Colors.green.shade50,
                    icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('confirm'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddTenantDialog({TenantModel? tenantToEdit}) {
    final isEdit = tenantToEdit != null;
    final nameCtrl = TextEditingController(text: tenantToEdit?.name ?? '');
    final phoneCtrl = TextEditingController(text: tenantToEdit?.phoneNumber ?? '');
    final customRoomCtrl = TextEditingController(text: tenantToEdit?.roomNumber ?? '');

    // Get floor and room controllers
    final floorsCtrl = Get.isRegistered<OwnerFloorsController>()
        ? Get.find<OwnerFloorsController>()
        : (Get.isRegistered<ApiService>()
            ? Get.put(OwnerFloorsController(apiService: Get.find<ApiService>()))
            : null);
    final roomsCtrl = Get.isRegistered<OwnerRoomsController>()
        ? Get.find<OwnerRoomsController>()
        : (Get.isRegistered<ApiService>()
            ? Get.put(OwnerRoomsController(apiService: Get.find<ApiService>()))
            : Get.put(OwnerRoomsController()));

    // Collect available floors
    final floorOptions = <_FloorOption>[];
    final seenFloors = <int>{};

    if (floorsCtrl != null) {
      for (var f in floorsCtrl.floors) {
        final fNum = f.floorNumber;
        if (!seenFloors.contains(fNum)) {
          seenFloors.add(fNum);
          floorOptions.add(_FloorOption(
            floorNumber: fNum,
            displayName: f.name.isNotEmpty ? f.name : _formatFloorName(fNum),
          ));
        }
      }
    }

    for (var r in roomsCtrl.rooms) {
      if (r.floor != null && !seenFloors.contains(r.floor!)) {
        seenFloors.add(r.floor!);
        floorOptions.add(_FloorOption(
          floorNumber: r.floor!,
          displayName: r.floorDisplayName,
        ));
      }
    }

    if (floorOptions.isEmpty) {
      floorOptions.add(_FloorOption(
        floorNumber: 1,
        displayName: LanguageService.isKhmer ? "ជាន់ផ្ទាល់ដី" : "Ground Floor",
      ));
      floorOptions.add(_FloorOption(
        floorNumber: 2,
        displayName: LanguageService.isKhmer ? "ជាន់ទី ១" : "Floor 1",
      ));
      floorOptions.add(_FloorOption(
        floorNumber: 3,
        displayName: LanguageService.isKhmer ? "ជាន់ទី ២" : "Floor 2",
      ));
    }

    floorOptions.sort((a, b) => a.floorNumber.compareTo(b.floorNumber));

    // Initial floor
    int selectedFloorNumber = floorOptions.first.floorNumber;
    if (tenantToEdit?.floor != null) {
      final match = floorOptions.firstWhereOrNull((f) =>
          f.displayName.toLowerCase() == tenantToEdit!.floor!.toLowerCase() ||
          tenantToEdit.floor!.contains(f.floorNumber.toString()));
      if (match != null) {
        selectedFloorNumber = match.floorNumber;
      }
    }

    String? selectedRoomNumber = tenantToEdit?.roomNumber;
    bool isCustomRoom = false;
    bool autoGenerateFirstInvoice = !isEdit;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // All rooms belonging to the selected floor
          final allRoomsOnFloor = roomsCtrl.rooms
              .where((r) => r.floor == selectedFloorNumber)
              .toList();

          // Only rooms that are NOT already occupied by another tenant
          final availableRoomsOnFloor = allRoomsOnFloor.where((r) {
            final rNum = (r.roomNumber ?? '').trim();
            if (isEdit && tenantToEdit?.roomNumber?.trim().toLowerCase() == rNum.toLowerCase()) {
              return true;
            }
            return !controller.isRoomOccupied(rNum, excludeTenantId: tenantToEdit?.id);
          }).toList();

          // Auto-select valid room for current floor if available
          if (!isCustomRoom) {
            final isValid = availableRoomsOnFloor.any((r) => r.roomNumber == selectedRoomNumber);
            if (!isValid) {
              selectedRoomNumber = availableRoomsOnFloor.isNotEmpty
                  ? availableRoomsOnFloor.first.roomNumber
                  : null;
            }
          }

          final selectedFloorObj = floorOptions.firstWhere(
            (f) => f.floorNumber == selectedFloorNumber,
            orElse: () => floorOptions.first,
          );

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_add_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isEdit
                        ? (LanguageService.isKhmer ? 'កែសម្រួលអ្នកជួល' : 'Edit Tenant')
                        : 'add_tenant'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'full_name'.tr,
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Phone Number
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'phone'.tr,
                        prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Floor Selector Dropdown
                    DropdownButtonFormField<int>(
                      value: selectedFloorNumber,
                      decoration: InputDecoration(
                        labelText: 'floor_number'.tr,
                        prefixIcon: const Icon(Icons.layers_outlined, color: AppColors.primary, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: floorOptions.map((f) {
                        return DropdownMenuItem<int>(
                          value: f.floorNumber,
                          child: Text(
                            f.displayName,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedFloorNumber = val;
                            selectedRoomNumber = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Dynamic Room Selector / Manual Room Input based on selected floor
                    if (!isCustomRoom) ...[
                      if (availableRoomsOnFloor.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          value: selectedRoomNumber,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'room_number'.tr,
                            prefixIcon: const Icon(Icons.meeting_room_outlined, color: AppColors.primary, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          items: availableRoomsOnFloor.map((r) {
                            final rNum = r.roomNumber ?? 'Room';
                            final isCurrent = isEdit && tenantToEdit?.roomNumber?.trim().toLowerCase() == rNum.toLowerCase();
                            final statusLabel = isCurrent
                                ? (LanguageService.isKhmer ? "បន្ទប់បច្ចុប្បន្ន" : "Current")
                                : (LanguageService.isKhmer ? "ទំនេរ" : "Available");

                            return DropdownMenuItem<String>(
                              value: rNum,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${'room'.tr} $rNum",
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isCurrent ? Colors.blue.shade50 : AppColors.primarySoft,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isCurrent ? Colors.blue.shade700 : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setDialogState(() {
                              selectedRoomNumber = val;
                            });
                          },
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.block_rounded, size: 18, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  allRoomsOnFloor.isNotEmpty
                                      ? (LanguageService.isKhmer
                                          ? "គ្រប់បន្ទប់នៅលើជាន់នេះមានអ្នកជួលរួចហើយ គ្មានបន្ទប់ទំនេរទេ"
                                          : "All rooms on this floor are occupied (no vacant rooms)")
                                      : (LanguageService.isKhmer
                                          ? "មិនទាន់មានបន្ទប់នៅលើជាន់នេះទេ"
                                          : "No registered rooms on this floor"),
                                  style: TextStyle(fontSize: 11, color: Colors.red.shade900, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () {
                            setDialogState(() {
                              isCustomRoom = true;
                              customRoomCtrl.text = selectedRoomNumber ?? '';
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                            child: Text(
                              LanguageService.isKhmer ? "បញ្ចូលលេខបន្ទប់ដោយផ្ទាល់" : "Enter room number manually",
                              style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: customRoomCtrl,
                        decoration: InputDecoration(
                          labelText: 'room_number'.tr,
                          prefixIcon: const Icon(Icons.meeting_room_outlined, color: AppColors.primary, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      if (availableRoomsOnFloor.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () {
                              setDialogState(() {
                                isCustomRoom = false;
                                selectedRoomNumber = availableRoomsOnFloor.first.roomNumber;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                              child: Text(
                                LanguageService.isKhmer ? "ជ្រើសរើសពីបញ្ជីបន្ទប់ទំនេរ" : "Select from vacant room list",
                                style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                    if (!isEdit) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: autoGenerateFirstInvoice ? AppColors.primarySoft : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: autoGenerateFirstInvoice ? AppColors.primary.withOpacity(0.3) : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: autoGenerateFirstInvoice,
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) {
                                setDialogState(() {
                                  autoGenerateFirstInvoice = val ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    autoGenerateFirstInvoice = !autoGenerateFirstInvoice;
                                  });
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      LanguageService.isKhmer
                                          ? "បង្កើតវិក្កយបត្រខែដំបូងដោយស្វ័យប្រវត្តិ"
                                          : "Auto-generate first month invoice",
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    ),
                                    Text(
                                      LanguageService.isKhmer
                                          ? "ចេញវិក្កយបត្រថ្លៃឈ្នួលបន្ទប់ និងថ្លៃសំរាមភ្លាមៗ"
                                          : "Creates rent and garbage invoice right away",
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('cancel'.tr, style: const TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () {
                  final tenantName = nameCtrl.text.trim();
                  final phone = phoneCtrl.text.trim();
                  final roomNumber = isCustomRoom
                      ? customRoomCtrl.text.trim()
                      : (selectedRoomNumber ?? customRoomCtrl.text.trim());
                  final floorDisplayName = selectedFloorObj.displayName;

                  if (tenantName.isEmpty) {
                    Get.snackbar(
                      'error'.tr,
                      LanguageService.isKhmer ? 'សូមបញ្ចូលឈ្មោះអ្នកជួល' : 'Please enter tenant name',
                      backgroundColor: Colors.red.shade50,
                      margin: const EdgeInsets.all(16),
                    );
                    return;
                  }

                  if (roomNumber.isEmpty) {
                    Get.snackbar(
                      'error'.tr,
                      LanguageService.isKhmer ? 'សូមជ្រើសរើស ឬបញ្ចូលលេខបន្ទប់' : 'Please select or enter room number',
                      backgroundColor: Colors.red.shade50,
                      margin: const EdgeInsets.all(16),
                    );
                    return;
                  }

                  // Check if room is already occupied
                  if (controller.isRoomOccupied(roomNumber, excludeTenantId: tenantToEdit?.id)) {
                    Get.snackbar(
                      'error'.tr,
                      LanguageService.isKhmer
                          ? 'បន្ទប់លេខ $roomNumber មានគេជួលរួចហើយ មិនអាចជួលបានទៀតទេ'
                          : 'Room $roomNumber is already occupied. Cannot rent again.',
                      backgroundColor: Colors.red.shade50,
                      colorText: Colors.red.shade800,
                      icon: const Icon(Icons.error_outline, color: Colors.red),
                      margin: const EdgeInsets.all(16),
                    );
                    return;
                  }

                  AppFirebaseService.logAddTenantForm(
                    tenantName: tenantName,
                    roomNumber: roomNumber,
                    success: true,
                  );

                  final oldRoomNumber = tenantToEdit?.roomNumber;
                  if (isEdit) {
                    controller.updateTenant(
                      id: tenantToEdit.id!,
                      name: tenantName,
                      roomNumber: roomNumber,
                      floor: floorDisplayName,
                      phone: phone.isNotEmpty ? phone : "012345678",
                    );
                    if (oldRoomNumber != null && oldRoomNumber.trim().toLowerCase() != roomNumber.trim().toLowerCase()) {
                      final hasOther = controller.tenants.any((t) =>
                          t.id != tenantToEdit.id &&
                          (t.roomNumber ?? '').trim().toLowerCase() == oldRoomNumber.trim().toLowerCase());
                      if (!hasOther) {
                        roomsCtrl.setRoomAvailability(oldRoomNumber, true);
                      }
                    }
                  } else {
                    controller.addTenant(
                      name: tenantName,
                      roomNumber: roomNumber,
                      floor: floorDisplayName,
                      phone: phone.isNotEmpty ? phone : "012345678",
                    );

                    if (autoGenerateFirstInvoice) {
                      final invoicesCtrl = Get.isRegistered<OwnerInvoicesController>()
                          ? Get.find<OwnerInvoicesController>()
                          : Get.put(OwnerInvoicesController());

                      final matchingRoom = roomsCtrl.rooms.firstWhereOrNull((r) =>
                          (r.roomNumber ?? '').trim().toLowerCase() == roomNumber.trim().toLowerCase());
                      final rentAmount = matchingRoom?.price ?? 50.0;

                      final propName = Get.isRegistered<OwnerMainController>()
                          ? Get.find<OwnerMainController>().selectedPropertyName.value
                          : "My Property";

                      final newTenantObj = TenantModel(
                        name: tenantName,
                        roomNumber: roomNumber,
                        floor: floorDisplayName,
                        phoneNumber: phone.isNotEmpty ? phone : "012345678",
                      );

                      invoicesCtrl.generateMoveInInvoice(
                        tenant: newTenantObj,
                        rentAmount: rentAmount,
                        propertyName: propName,
                      );
                    }
                  }

                  // Auto mark room as occupied
                  roomsCtrl.setRoomAvailability(roomNumber, false);

                  Navigator.pop(ctx);
                  Get.snackbar(
                    'success'.tr,
                    (autoGenerateFirstInvoice && !isEdit)
                        ? (LanguageService.isKhmer
                            ? "$tenantName • បន្ទប់ $roomNumber • បានបង្កើតវិក្កយបត្រស្វ័យប្រវត្តិ"
                            : "$tenantName • Room $roomNumber • Auto-generated invoice")
                        : "$tenantName • ${'room'.tr} $roomNumber • $floorDisplayName",
                    backgroundColor: Colors.green.shade50,
                    margin: const EdgeInsets.all(16),
                    icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('confirm'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      LanguageService.currentLocale.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: widget.showAppBar
            ? CustomAppBar(
                title: 'tenants'.tr,
                showProperty: false,
                showLanguage: false,
                isOwner: true,
              )
            : null,
        body: Column(
          children: [
            // Filter header (Photo 6)
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('all'.tr, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                        const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Tenants List (Photo 6)
            Expanded(
              child: Obx(() {
                final allTenants = controller.filteredTenants;
                if (allTenants.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'no_data'.tr,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final limit = _visibleLimit.value;
                final displayedTenants = allTenants.take(limit).toList();
                final hasMore = limit < allTenants.length;
                final loading = _isLoadingMore.value;
                final extraCount = (hasMore || allTenants.length > 5) ? 1 : 0;

                return NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 60) {
                      _loadMore();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayedTenants.length + extraCount,
                    itemBuilder: (ctx, i) {
                      if (i == displayedTenants.length) {
                        if (hasMore) {
                          return loading
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          LanguageService.isKhmer ? "កំពុងទាញយកទិន្នន័យ ៥ ទៀត..." : "Loading 5 more...",
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : InkWell(
                                  onTap: _loadMore,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 4, bottom: 16),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.primary),
                                        const SizedBox(width: 6),
                                        Text(
                                          LanguageService.isKhmer
                                              ? "បង្ហាញ ៥ ទៀត • នៅសល់ ${allTenants.length - displayedTenants.length}"
                                              : "Show 5 More • ${allTenants.length - displayedTenants.length} remaining",
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: Text(
                                LanguageService.isKhmer
                                    ? "បានបង្ហាញអ្នកជួលទាំងអស់ហើយ • សរុប ${allTenants.length}"
                                    : "All tenants loaded • ${allTenants.length} total",
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ),
                          );
                        }
                      }

                      final t = displayedTenants[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.primarySoft,
                                  child: Text(
                                    (t.name != null && t.name!.isNotEmpty) ? t.name!.substring(0, 1) : "T",
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.name ?? "Tenant",
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${t.floor ?? ''} • ${t.roomNumber ?? ''}",
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary, size: 20),
                                  onPressed: () => _showActionSheet(t),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(height: 1, color: AppColors.border),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.email_outlined, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(t.email ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                const Spacer(),
                                const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(t.phoneNumber ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddTenantDialog,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white, size: 26),
        ),
      );
    });
  }
}
