import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/language_service.dart';
import '../../../models/rental/invoice_model.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/custom_app_bar.dart';
import '../tenants/owner_tenants_controller.dart';
import 'owner_invoices_controller.dart';

class OwnerInvoicesView extends StatefulWidget {
  const OwnerInvoicesView({super.key});

  @override
  State<OwnerInvoicesView> createState() => _OwnerInvoicesViewState();
}

class _OwnerInvoicesViewState extends State<OwnerInvoicesView> {
  late final OwnerInvoicesController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<OwnerInvoicesController>()
        ? Get.find<OwnerInvoicesController>()
        : Get.put(OwnerInvoicesController());
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

  void _showCreateInvoiceDialog() {
    String defaultTenant = "";
    String defaultRoom = "";
    if (Get.isRegistered<OwnerTenantsController>()) {
      final tList = Get.find<OwnerTenantsController>().tenants;
      if (tList.isNotEmpty) {
        defaultTenant = tList.first.name ?? "";
        defaultRoom = tList.first.roomNumber ?? "";
      }
    }
    final tenantCtrl = TextEditingController(text: defaultTenant);
    final roomCtrl = TextEditingController(text: defaultRoom);
    final rentCtrl = TextEditingController(text: "50.00");
    final elecCtrl = TextEditingController(text: "0.0");
    final waterCtrl = TextEditingController(text: "0.0");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(LanguageService.isKhmer ? "បង្កើតវិក្កយបត្រថ្មី" : "Create New Invoice", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: tenantCtrl, decoration: InputDecoration(labelText: 'tenant_label'.tr)),
              TextField(controller: roomCtrl, decoration: InputDecoration(labelText: 'room_number'.tr)),
              TextField(controller: rentCtrl, decoration: InputDecoration(labelText: 'rent_price_label'.tr), keyboardType: TextInputType.number),
              TextField(controller: elecCtrl, decoration: InputDecoration(labelText: "${'electricity_fee_item'.tr} (kWh)"), keyboardType: TextInputType.number),
              TextField(controller: waterCtrl, decoration: InputDecoration(labelText: "${'water_fee_item'.tr} (m³)"), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () {
              final rent = double.tryParse(rentCtrl.text.trim()) ?? 50.0;
              final elec = double.tryParse(elecCtrl.text.trim()) ?? 0.0;
              final water = double.tryParse(waterCtrl.text.trim()) ?? 0.0;
              final total = rent + (elec * 0.12) + (water * 1.50);

              final newInv = InvoiceModel(
                id: DateTime.now().millisecondsSinceEpoch,
                invoiceNo: "INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
                propertyName: "My Home",
                tenantName: tenantCtrl.text.trim(),
                roomNumber: roomCtrl.text.trim(),
                floor: LanguageService.isKhmer ? "ជាន់ទី ១" : "Floor 1",
                issueDate: "Apr 9, 2026",
                dueDate: "Apr 15, 2026",
                rentAmount: rent,
                electricityUnits: elec,
                electricityRate: 0.12,
                waterUnits: water,
                waterRate: 1.50,
                totalAmount: total,
                status: "UNPAID",
              );
              controller.createInvoice(newInv);
              Navigator.pop(ctx);
              Get.snackbar('success'.tr, "${newInv.invoiceNo}", backgroundColor: Colors.green.shade50);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: Text('save'.tr),
          ),
        ],
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
        appBar: CustomAppBar(
          title: 'invoices'.tr,
          propertyDropdownText: "My Home",
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
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
                    icon: Icons.attach_money,
                    color: AppColors.accentBlue,
                  ),
                  _InvoiceMetricCard(
                    title: 'collected'.tr,
                    value: "\$${controller.totalCollectedRevenue.toStringAsFixed(2)}",
                    icon: Icons.check_circle_outline,
                    color: AppColors.primary,
                  ),
                  _InvoiceMetricCard(
                    title: 'unpaid_status'.tr,
                    value: "${controller.unpaidCount}",
                    icon: Icons.access_time,
                    color: AppColors.accentOrange,
                  ),
                  _InvoiceMetricCard(
                    title: 'overdue_status'.tr,
                    value: "${controller.overdueCount}",
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
                final list = controller.filteredInvoices;
                if (list.isEmpty) {
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

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final inv = list[i];
                    final isPaid = inv.isPaid;
                    return InkWell(
                      onTap: () => _showInvoiceDetailModal(inv),
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
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
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
      onTap: () => controller.selectedFilter.value = code,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _InvoiceMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InvoiceMetricCard({
    required this.title,
    required this.value,
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
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
