import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/rental/invoice_model.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/custom_app_bar.dart';

class OwnerInvoicesView extends StatefulWidget {
  const OwnerInvoicesView({super.key});

  @override
  State<OwnerInvoicesView> createState() => _OwnerInvoicesViewState();
}

class _OwnerInvoicesViewState extends State<OwnerInvoicesView> {
  String selectedFilter = "ALL";
  final List<InvoiceModel> invoices = [
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
              // Modal Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(6)),
                            child: const Icon(Icons.home_outlined, size: 16, color: AppColors.primary),
                          ),
                          const SizedBox(width: 6),
                          Text(inv.propertyName ?? "My Home", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text("Phnom Penh", style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("វិក្កយបត្រ (Invoice)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(inv.invoiceNo ?? "INV-001", style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 14),

              // Tenant & Dates
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("វិក្កយបត្រជូន / Billed To", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(inv.tenantName ?? "Tenant", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text("បន្ទប់: ${inv.roomNumber ?? ''} • ${inv.floor ?? ''}", style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("កាលបរិច្ឆេទចេញ / Issued", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text(inv.issueDate ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      const SizedBox(height: 4),
                      const Text("កាលបរិច្ឆេទផុតកំណត់ / Due", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text(inv.dueDate ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.danger)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Breakdown Table (Photo 5)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text("ការពិពណ៌នា", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                          Expanded(flex: 2, child: Text("ការប្រើប្រាស់", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                          Expanded(flex: 2, child: Text("ចំនួនទឹកប្រាក់", textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                        ],
                      ),
                    ),
                    _buildInvoiceRow("ថ្លៃឈ្នួលបន្ទប់ (Room Rent)", "—", "\$${inv.rentAmount?.toStringAsFixed(2) ?? '50.00'}", Icons.meeting_room_outlined),
                    _buildInvoiceRow("អគ្គិសនី (@ \$0.12/kWh)", "1 unit", "\$0.12", Icons.bolt_outlined),
                    _buildInvoiceRow("ទឹក (@ \$1.50/m³)", "1 unit", "\$1.50", Icons.water_drop_outlined),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Total box (Photo 5)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("សរុបត្រូវបង់ (Total Due)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      "\$${inv.totalAmount?.toStringAsFixed(2) ?? '51.62'}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // KHQR Card Preview (Photo 5)
              Center(
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(4)),
                        child: const Text("ABA' QR", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 130,
                        height: 130,
                        color: AppColors.background,
                        child: const Center(
                          child: Icon(Icons.qr_code_2_rounded, size: 100, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text("ស្កេនដើម្បីបង់ប្រាក់ / Scan to Pay", style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons (Photo 5)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Get.snackbar("Telegram", "ផ្ញើវិក្កយបត្រតាម Telegram រួចរាល់", backgroundColor: Colors.white);
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
                        Get.snackbar("Shared", "បានចែករំលែក Link វិក្កយបត្រ", backgroundColor: Colors.white);
                      },
                      icon: const Icon(Icons.share_outlined, size: 16),
                      label: const Text("ចែករំលែក", style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Get.snackbar("Download", "ទាញយកវិក្កយបត្រជា PDF រួចរាល់", backgroundColor: Colors.green.shade50);
                      },
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text("ទាញយក", style: TextStyle(fontSize: 11)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: "វិក្កយបត្រ",
        propertyDropdownText: "My Home",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 2x2 Metric Cards Grid (Photo 4)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.4,
              children: const [
                _InvoiceMetricCard(title: "រំពឹងទុក (Expected)", value: "\$151.62", icon: Icons.attach_money, color: AppColors.accentBlue),
                _InvoiceMetricCard(title: "ប្រមូលបាន (Collected)", value: "\$100.00", icon: Icons.check_circle_outline, color: AppColors.primary),
                _InvoiceMetricCard(title: "មិនទាន់បង់ (Unpaid)", value: "1", icon: Icons.access_time, color: AppColors.accentOrange),
                _InvoiceMetricCard(title: "ហួសកាលកំណត់ (Overdue)", value: "0", icon: Icons.warning_amber_rounded, color: AppColors.danger),
              ],
            ),

            const SizedBox(height: 16),

            // Filter Tabs (Photo 4)
            Row(
              children: [
                _buildFilterTab("ALL", "ទាំងអស់ (All)"),
                const SizedBox(width: 6),
                _buildFilterTab("UNPAID", "មិនទាន់បង់"),
                const SizedBox(width: 6),
                _buildFilterTab("PAID", "បានបង់"),
              ],
            ),

            const SizedBox(height: 14),

            // Invoices List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: invoices.length,
              itemBuilder: (ctx, i) {
                final inv = invoices[i];
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
                              Text(inv.tenantName ?? "Tenant", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text("បន្ទប់: ${inv.roomNumber ?? ''} • ${inv.issueDate ?? ''}", style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "\$${inv.totalAmount?.toStringAsFixed(2) ?? '50.00'}",
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
                                isPaid ? "បានបង់" : "មិនទាន់បង់",
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String code, String label) {
    final isSelected = selectedFilter == code;
    return InkWell(
      onTap: () => setState(() => selectedFilter = code),
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
