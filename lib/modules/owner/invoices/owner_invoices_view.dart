import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/url_service.dart';
import '../../../models/rental/invoice_model.dart';
import '../../../models/rental/tenant_model.dart';
import '../../../models/rental/room_model.dart';
import '../../../widgets/animated_widgets.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/custom_app_bar.dart';
import '../tenants/owner_tenants_controller.dart';
import '../rooms/owner_rooms_controller.dart';
import '../owner_main_controller.dart';
import 'owner_invoices_controller.dart';

class OwnerInvoicesView extends StatefulWidget {
  final bool showAppBar;
  const OwnerInvoicesView({super.key, this.showAppBar = false});

  @override
  State<OwnerInvoicesView> createState() => _OwnerInvoicesViewState();
}

class _OwnerInvoicesViewState extends State<OwnerInvoicesView> {
  late final OwnerInvoicesController controller;
  final RxInt _visibleLimit = 5.obs;
  final RxBool _isLoadingMore = false.obs;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<OwnerInvoicesController>()
        ? Get.find<OwnerInvoicesController>()
        : Get.put(OwnerInvoicesController());
  }

  void _loadMore() {
    final total = controller.filteredInvoices.length;
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

  void _confirmDeleteInvoice(InvoiceModel inv, {VoidCallback? onDeleted}) {
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
              ? "តើអ្នកពិតជាចង់លុបវិក្កយបត្រ ${inv.invoiceNo ?? ''} នេះមែនទេ? សកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ។"
              : "Are you sure you want to delete invoice ${inv.invoiceNo ?? ''}? This action cannot be undone.",
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'cancel'.tr,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteInvoice(inv.id);
              Navigator.pop(ctx);
              onDeleted?.call();
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

  void _showInvoiceDetailModal(InvoiceModel inv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.invoiceNo ?? "INV-000",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
                      ),
                      Text("${'invoice_date'.tr}: ${inv.issueDate ?? ''}", style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: inv.isPaid ? AppColors.primarySoft : AppColors.accentOrangeLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          inv.isPaid ? 'paid_status'.tr : 'unpaid_status'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: inv.isPaid ? AppColors.primary : AppColors.accentOrange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: LanguageService.isKhmer ? "លុបវិក្កយបត្រ" : "Delete",
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 22),
                        onPressed: () {
                          _confirmDeleteInvoice(inv, onDeleted: () => Navigator.pop(ctx));
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.border),
              const SizedBox(height: 16),

              // Property & Tenant info card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.home_work_outlined, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(inv.propertyName ?? "My Home", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        Text("${'room_label_prefix'.tr} ${inv.roomNumber ?? ''}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(child: Text("${'tenant_label'.tr}: ${inv.tenantName ?? 'N/A'}", style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                        Text(inv.floor ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Text('bill_breakdown'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),

              // Breakdown Table
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildInvoiceRow('room_rent_fee'.tr, "-", "\$${inv.rentAmount?.toStringAsFixed(2) ?? '0.00'}", Icons.meeting_room_outlined),
                    const Divider(height: 1, color: AppColors.border),
                    _buildInvoiceRow('electricity_fee_item'.tr, "${inv.electricityUnits ?? 0} kWh", "\$${((inv.electricityUnits ?? 0) * (inv.electricityRate ?? 0.12)).toStringAsFixed(2)}", Icons.bolt_outlined),
                    const Divider(height: 1, color: AppColors.border),
                    _buildInvoiceRow('water_fee_item'.tr, "${inv.waterUnits ?? 0} m³", "\$${((inv.waterUnits ?? 0) * (inv.waterRate ?? 1.50)).toStringAsFixed(2)}", Icons.water_drop_outlined),
                    const Divider(height: 1, color: AppColors.border),
                    _buildInvoiceRow('garbage_fee_item'.tr, LanguageService.isKhmer ? "1 ខែ" : "1 mo", "\$2.00", Icons.delete_outline),
                    const Divider(height: 1, color: AppColors.border),
                    Container(
                      color: AppColors.primarySoft.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('total_due'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                          Text("\$${inv.totalAmount?.toStringAsFixed(2) ?? '0.00'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Status Toggle Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (inv.isPaid) {
                      controller.markAsUnpaid(inv.id);
                      Get.snackbar('settings'.tr, 'marked_as_unpaid_msg'.tr, backgroundColor: Colors.white);
                    } else {
                      controller.markAsPaid(inv.id);
                      Get.snackbar('success'.tr, 'payment_recorded_msg'.tr, backgroundColor: Colors.green.shade50);
                    }
                    Navigator.pop(ctx);
                  },
                  icon: Icon(inv.isPaid ? Icons.undo_rounded : Icons.check_circle_outline, size: 18),
                  label: Text(inv.isPaid ? 'mark_as_unpaid'.tr : 'mark_as_paid'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: inv.isPaid ? AppColors.accentOrange : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        UrlService.sendInvoiceToTelegram(
                          tenantName: inv.tenantName ?? '',
                          roomNumber: inv.roomNumber ?? '',
                          totalAmount: inv.totalAmount ?? 0.0,
                        );
                        Get.snackbar("Telegram", 'telegram_sent_msg'.tr, backgroundColor: Colors.white);
                      },
                      icon: const Icon(Icons.send_rounded, size: 16, color: AppColors.primary),
                      label: const Text("Telegram", style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Get.snackbar("Shared", 'link_shared_msg'.tr, backgroundColor: Colors.white);
                      },
                      icon: const Icon(Icons.share_outlined, size: 16),
                      label: Text('share'.tr, style: const TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Get.snackbar("Download", 'pdf_downloaded_msg'.tr, backgroundColor: Colors.green.shade50);
                      },
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: Text('download'.tr, style: const TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _confirmDeleteInvoice(inv, onDeleted: () => Navigator.pop(ctx));
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                  label: Text(
                    LanguageService.isKhmer ? "លុបវិក្កយបត្រនេះ" : "Delete This Invoice",
                    style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    foregroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String desc, String usage, String amount, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(icon, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(child: Text(desc, style: const TextStyle(fontSize: 12))),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(usage, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
          Expanded(flex: 2, child: Text(amount, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildAutoGenerateBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF0F9D58)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LanguageService.isKhmer ? "បង្កើតវិក្កយបត្រប្រចាំខែ Auto" : "Auto-Generate Monthly Invoices",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  LanguageService.isKhmer
                      ? "ចេញវិក្កយបត្រសម្រាប់គ្រប់អ្នកជួលដោយចុចតែ ១ ដង"
                      : "Batch-create invoices for all active tenants",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _showAutoGenerateMonthlyDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              LanguageService.isKhmer ? "បង្កើតឥឡូវ" : "Generate",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showAutoGenerateMonthlyDialog() {
    final tenantsCtrl = Get.isRegistered<OwnerTenantsController>()
        ? Get.find<OwnerTenantsController>()
        : Get.put(OwnerTenantsController());
    final roomsCtrl = Get.isRegistered<OwnerRoomsController>()
        ? Get.find<OwnerRoomsController>()
        : Get.put(OwnerRoomsController());
    final propName = Get.isRegistered<OwnerMainController>()
        ? Get.find<OwnerMainController>().selectedPropertyName.value
        : "My Property";

    final tenants = tenantsCtrl.tenants;

    if (tenants.isEmpty) {
      Get.snackbar(
        'notice'.tr,
        LanguageService.isKhmer
            ? "មិនទាន់មានអ្នកជួលនៅឡើយទេ សូមបន្ថែមអ្នកជួលជាមុនសិន"
            : "No active tenants found. Please add tenants first.",
        backgroundColor: Colors.amber.shade50,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final now = DateTime.now();
    final monthYearLabel = LanguageService.isKhmer
        ? "ខែ ${['មករា', 'កុម្ភៈ', 'មីនា', 'មេសា', 'ឧសភា', 'មិថុនា', 'កក្កដា', 'សីហា', 'កញ្ញា', 'តុលា', 'វិច្ឆិកា', 'ធ្នូ'][now.month - 1]} ${now.year}"
        : "${['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][now.month - 1]} ${now.year}";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.flash_on_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LanguageService.isKhmer ? "បង្កើតវិក្កយបត្រប្រចាំខែស្វ័យប្រវត្តិ" : "Auto-Generate Monthly Invoices",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          monthYearLabel,
                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          "${tenants.length}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        Text(
                          LanguageService.isKhmer ? "អ្នកជួលសរុប" : "Total Tenants",
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Container(height: 30, width: 1, color: AppColors.border),
                    Column(
                      children: [
                        Text(
                          OwnerInvoicesController.formatDueDate(null, 7),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          LanguageService.isKhmer ? "កាលបរិច្ឆេទកំណត់បង់" : "Payment Due Date",
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                LanguageService.isKhmer ? "បញ្ជីអ្នកជួលដែលត្រូវចេញវិក្កយបត្រ៖" : "Tenants to be invoiced:",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.35),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tenants.length,
                  itemBuilder: (ctx, i) {
                    final t = tenants[i];
                    final matchRoom = roomsCtrl.rooms.firstWhereOrNull(
                        (r) => (r.roomNumber ?? '').trim().toLowerCase() == (t.roomNumber ?? '').trim().toLowerCase());
                    final rent = matchRoom?.price ?? 50.0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primarySoft,
                            child: Text(
                              (t.name != null && t.name!.isNotEmpty) ? t.name!.substring(0, 1) : "T",
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.name ?? "Tenant", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                Text("${t.floor ?? ''} • ${'room_label_prefix'.tr} ${t.roomNumber ?? ''}", style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Text(
                            "\$${rent.toStringAsFixed(0)}/mo",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final created = controller.generateMonthlyInvoices(
                      activeTenants: tenants,
                      allRooms: roomsCtrl.rooms,
                      propertyName: propName,
                    );
                    Navigator.pop(ctx);
                    if (created > 0) {
                      Get.snackbar(
                        'success'.tr,
                        LanguageService.isKhmer
                            ? "បានបង្កើតវិក្កយបត្រប្រចាំខែចំនួន $created ដោយជោគជ័យ!"
                            : "Successfully generated $created monthly invoices!",
                        backgroundColor: Colors.green.shade50,
                        icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                        margin: const EdgeInsets.all(16),
                      );
                    } else {
                      Get.snackbar(
                        'notice'.tr,
                        LanguageService.isKhmer
                            ? "អ្នកជួលទាំងអស់សុទ្ធតែមានវិក្កយបត្រសម្រាប់ខែនេះរួចហើយ"
                            : "All tenants already have invoices for this month",
                        backgroundColor: Colors.amber.shade50,
                        margin: const EdgeInsets.all(16),
                      );
                    }
                  },
                  icon: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 20),
                  label: Text(
                    LanguageService.isKhmer ? "ចេញវិក្កយបត្រទាំងអស់ឥឡូវនេះ" : "Generate All Invoices Now",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateInvoiceDialog({TenantModel? presetTenant}) {
    final tenantsCtrl = Get.isRegistered<OwnerTenantsController>()
        ? Get.find<OwnerTenantsController>()
        : Get.put(OwnerTenantsController());
    final roomsCtrl = Get.isRegistered<OwnerRoomsController>()
        ? Get.find<OwnerRoomsController>()
        : Get.put(OwnerRoomsController());
    final propName = Get.isRegistered<OwnerMainController>()
        ? Get.find<OwnerMainController>().selectedPropertyName.value
        : "My Property";

    final tList = tenantsCtrl.tenants;

    TenantModel? selectedTenant = presetTenant ?? (tList.isNotEmpty ? tList.first : null);

    String currentTenantName = selectedTenant?.name ?? "";
    String currentRoomNumber = selectedTenant?.roomNumber ?? "";
    String currentFloor = selectedTenant?.floor ?? "Ground Floor";

    final matchingRoom = roomsCtrl.rooms.firstWhereOrNull((r) =>
        (r.roomNumber ?? '').trim().toLowerCase() == currentRoomNumber.trim().toLowerCase());
    double defaultRent = matchingRoom?.price ?? 50.0;

    final tenantCtrl = TextEditingController(text: currentTenantName);
    final roomCtrl = TextEditingController(text: currentRoomNumber);
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
                    LanguageService.isKhmer ? "បង្កើតវិក្កយបត្រថ្មី" : "Create New Invoice",
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
                  if (tList.isNotEmpty && presetTenant == null) ...[
                    Text(
                      LanguageService.isKhmer ? "ជ្រើសរើសអ្នកជួល" : "Select Tenant",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<TenantModel>(
                      value: selectedTenant,
                      isExpanded: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: tList.map((t) {
                        return DropdownMenuItem<TenantModel>(
                          value: t,
                          child: Text("${t.name ?? 'Tenant'} (${'room_label_prefix'.tr} ${t.roomNumber ?? ''})"),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedTenant = val;
                            tenantCtrl.text = val.name ?? '';
                            roomCtrl.text = val.roomNumber ?? '';
                            currentFloor = val.floor ?? 'Ground Floor';
                            final match = roomsCtrl.rooms.firstWhereOrNull((r) =>
                                (r.roomNumber ?? '').trim().toLowerCase() == (val.roomNumber ?? '').trim().toLowerCase());
                            if (match?.price != null) {
                              rentCtrl.text = match!.price!.toStringAsFixed(2);
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    TextField(
                      controller: tenantCtrl,
                      decoration: InputDecoration(
                        labelText: 'tenant_label'.tr,
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
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
                    decoration: InputDecoration(
                      labelText: 'rent_price_label'.tr,
                      prefixIcon: const Icon(Icons.attach_money, color: AppColors.primary, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: elecCtrl,
                          decoration: InputDecoration(
                            labelText: "${'electricity_fee_item'.tr} (kWh)",
                            prefixIcon: const Icon(Icons.bolt, color: AppColors.primary, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: waterCtrl,
                          decoration: InputDecoration(
                            labelText: "${'water_fee_item'.tr} (m³)",
                            prefixIcon: const Icon(Icons.water_drop_outlined, color: AppColors.primary, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: garbageCtrl,
                    decoration: InputDecoration(
                      labelText: LanguageService.isKhmer ? "ថ្លៃសំរាម (\$)" : "Garbage Fee (\$)",
                      prefixIcon: const Icon(Icons.delete_outline, color: AppColors.primary, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr)),
              ElevatedButton(
                onPressed: () {
                  final tenantName = tenantCtrl.text.trim();
                  final roomNumber = roomCtrl.text.trim();
                  if (tenantName.isEmpty || roomNumber.isEmpty) {
                    Get.snackbar('error'.tr, LanguageService.isKhmer ? 'សូមបញ្ចូលឈ្មោះ និងលេខបន្ទប់' : 'Please enter name and room number', backgroundColor: Colors.red.shade50);
                    return;
                  }

                  final rent = double.tryParse(rentCtrl.text.trim()) ?? 50.0;
                  final elec = double.tryParse(elecCtrl.text.trim()) ?? 0.0;
                  final water = double.tryParse(waterCtrl.text.trim()) ?? 0.0;
                  final garbage = double.tryParse(garbageCtrl.text.trim()) ?? 2.0;
                  final total = rent + (elec * 0.25) + (water * 0.35) + garbage;

                  final now = DateTime.now();
                  final cleanRoom = roomNumber.replaceAll(' ', '');
                  final invNo = "INV-${now.year}${now.month.toString().padLeft(2, '0')}-$cleanRoom";

                  final newInv = InvoiceModel(
                    id: DateTime.now().millisecondsSinceEpoch,
                    invoiceNo: invNo,
                    propertyName: propName,
                    tenantName: tenantName,
                    roomNumber: roomNumber,
                    floor: currentFloor,
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

                  controller.createInvoice(newInv);
                  Navigator.pop(ctx);
                  Get.snackbar(
                    'success'.tr,
                    "${newInv.invoiceNo} - \$${total.toStringAsFixed(2)}",
                    backgroundColor: Colors.green.shade50,
                    icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: Text('save'.tr),
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
      // Rebuild when language changes
      LanguageService.currentLocale.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: widget.showAppBar
            ? CustomAppBar(
                title: 'invoices'.tr,
                showProperty: false,
                showLanguage: false,
                isOwner: true,
              )
            : null,
        body: NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 60) {
              _loadMore();
            }
            return false;
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Auto-Generate Monthly Invoices Banner
              _buildAutoGenerateBanner(),

              // 2x2 Dynamic Metric Cards Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.4,
                children: [
                  _InvoiceMetricCard(
                    title: 'expected'.tr,
                    value: "\$${controller.totalExpectedRevenue.toStringAsFixed(2)}",
                    numericValue: controller.totalExpectedRevenue,
                    prefix: "\$",
                    decimalPlaces: 2,
                    icon: Icons.attach_money,
                    color: AppColors.accentBlue,
                  ),
                  _InvoiceMetricCard(
                    title: 'collected'.tr,
                    value: "\$${controller.totalCollectedRevenue.toStringAsFixed(2)}",
                    numericValue: controller.totalCollectedRevenue,
                    prefix: "\$",
                    decimalPlaces: 2,
                    icon: Icons.check_circle_outline,
                    color: AppColors.primary,
                  ),
                  _InvoiceMetricCard(
                    title: 'unpaid_status'.tr,
                    value: "${controller.unpaidCount}",
                    numericValue: controller.unpaidCount,
                    icon: Icons.access_time,
                    color: AppColors.accentOrange,
                  ),
                  _InvoiceMetricCard(
                    title: 'overdue_status'.tr,
                    value: "${controller.overdueCount}",
                    numericValue: controller.overdueCount,
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.danger,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Filter Tabs
              Row(
                children: [
                  _buildFilterTab("ALL", 'all'.tr, controller.selectedFilter.value),
                  const SizedBox(width: 6),
                  _buildFilterTab("UNPAID", 'unpaid_status'.tr, controller.selectedFilter.value),
                  const SizedBox(width: 6),
                  _buildFilterTab("PAID", 'paid_status'.tr, controller.selectedFilter.value),
                ],
              ),

              const SizedBox(height: 14),

              // Invoices List
              Builder(builder: (ctx) {
                final allInvoices = controller.filteredInvoices;
                if (allInvoices.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'no_invoices_found'.tr,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Obx(() {
                  final limit = _visibleLimit.value;
                  final displayedInvoices = allInvoices.take(limit).toList();
                  final hasMore = limit < allInvoices.length;
                  final loading = _isLoadingMore.value;

                  return Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayedInvoices.length,
                        itemBuilder: (ctx, i) {
                          final inv = displayedInvoices[i];
                          final isPaid = inv.isPaid;
                          return InkWell(
                            onTap: () => _showInvoiceDetailModal(inv),
                            onLongPress: () => _confirmDeleteInvoice(inv),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isPaid ? AppColors.primarySoft : AppColors.accentOrangeLight,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isPaid ? Icons.check_circle_outline : Icons.receipt_long,
                                      color: isPaid ? AppColors.primary : AppColors.accentOrange,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(inv.invoiceNo ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                                        const SizedBox(height: 2),
                                        Text(inv.tenantName ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                        const SizedBox(height: 2),
                                        Text("${'room_label_prefix'.tr}: ${inv.roomNumber ?? ''} • ${inv.issueDate ?? ''}", style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "\$${inv.totalAmount?.toStringAsFixed(2) ?? '0.00'}",
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onSelected: (val) {
                                      if (val == 'details') {
                                        _showInvoiceDetailModal(inv);
                                      } else if (val == 'toggle_status') {
                                        if (isPaid) {
                                          controller.markAsUnpaid(inv.id);
                                        } else {
                                          controller.markAsPaid(inv.id);
                                        }
                                      } else if (val == 'delete') {
                                        _confirmDeleteInvoice(inv);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      PopupMenuItem(
                                        value: 'details',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primary),
                                            const SizedBox(width: 8),
                                            Text(LanguageService.isKhmer ? "មើលលម្អិត" : "View Details"),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'toggle_status',
                                        child: Row(
                                          children: [
                                            Icon(
                                              isPaid ? Icons.undo_rounded : Icons.check_circle_outline,
                                              size: 18,
                                              color: isPaid ? AppColors.accentOrange : AppColors.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(isPaid ? 'mark_as_unpaid'.tr : 'mark_as_paid'.tr),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuDivider(),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                                            const SizedBox(width: 8),
                                            Text(
                                              'delete'.tr,
                                              style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      if (hasMore) ...[
                        const SizedBox(height: 10),
                        loading
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
                                  width: double.infinity,
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
                                            ? "បង្ហាញ ៥ ទៀត • នៅសល់ ${allInvoices.length - displayedInvoices.length}"
                                            : "Show 5 More • ${allInvoices.length - displayedInvoices.length} remaining",
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ] else if (allInvoices.length > 5) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            LanguageService.isKhmer
                                ? "បានបង្ហាញវិក្កយបត្រទាំងអស់ហើយ • សរុប ${allInvoices.length}"
                                : "All invoices loaded • ${allInvoices.length} total",
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ],
                  );
                });
              }),
            ],
          ),
        ),
      ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateInvoiceDialog,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white, size: 26),
        ),
      );
    });
  }

  Widget _buildFilterTab(String code, String label, String currentSelected) {
    final isSelected = currentSelected == code;
    return InkWell(
      onTap: () {
        controller.selectedFilter.value = code;
        _resetPagination();
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class _InvoiceMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final num? numericValue;
  final String prefix;
  final int decimalPlaces;
  final IconData icon;
  final Color color;

  const _InvoiceMetricCard({
    required this.title,
    required this.value,
    this.numericValue,
    this.prefix = '',
    this.decimalPlaces = 0,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 6),
          if (numericValue != null)
            AnimatedCountText(
              value: numericValue!,
              prefix: prefix,
              decimalPlaces: decimalPlaces,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            )
          else
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
