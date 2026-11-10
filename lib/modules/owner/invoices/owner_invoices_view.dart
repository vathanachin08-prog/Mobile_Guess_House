import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/url_service.dart';
import '../../../models/rental/invoice_model.dart';
import '../../../models/rental/tenant_model.dart';
import '../../../widgets/animated_widgets.dart';
import '../../../widgets/app_clean_dialog.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final RxInt _visibleLimit = 5.obs;
  final RxBool _isLoadingMore = false.obs;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<OwnerInvoicesController>()
        ? Get.find<OwnerInvoicesController>()
        : Get.put(OwnerInvoicesController());
    controller.loadInvoices();
    _searchController.addListener(() {
      controller.searchQuery.value = _searchController.text;
      _resetPagination();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  String? _findTenantPhone(InvoiceModel inv) {
    if (Get.isRegistered<OwnerTenantsController>()) {
      final tenants = Get.find<OwnerTenantsController>().tenants;
      final match = tenants.firstWhereOrNull((t) {
        final sameName = (t.name ?? '').trim().toLowerCase() == (inv.tenantName ?? '').trim().toLowerCase();
        final sameRoom = (t.roomNumber ?? '').trim().toLowerCase() == (inv.roomNumber ?? '').trim().toLowerCase();
        return sameName || sameRoom;
      });
      return match?.phoneNumber;
    }
    return null;
  }

  void _showAlertTenantDialog(InvoiceModel inv) {
    final isKh = LanguageService.isKhmer;
    final phone = _findTenantPhone(inv);
    final tenantName = inv.tenantName ?? "Tenant";
    final roomNumber = inv.roomNumber ?? "";
    final amountStr = "\$${inv.totalAmount?.toStringAsFixed(2) ?? '0.00'}";
    final dueDateStr = inv.dueDate ?? '';
    final invoiceNo = inv.invoiceNo ?? 'INV';

    final reminderText = isKh
        ? "🔔 ការរំលឹកបង់ថ្លៃបន្ទប់ - RoomFinder KH\n\n"
            "អ្នកជួល៖ $tenantName\n"
            "បន្ទប់៖ $roomNumber\n"
            "លេខវិក្កយបត្រ៖ $invoiceNo\n"
            "ទឹកប្រាក់ត្រូវបង់៖ $amountStr\n"
            "${dueDateStr.isNotEmpty ? 'កាលបរិច្ឆេទកំណត់៖ $dueDateStr\n' : ''}"
            "ស្ថានភាព៖ មិនទាន់បង់ប្រាក់\n\n"
            "សូមមេត្តាពិនិត្យ និងទូទាត់ប្រាក់ឱ្យបានទាន់ពេលវេលា។ សូមអរគុណ!"
        : "🔔 Rent Payment Alert - RoomFinder KH\n\n"
            "Tenant: $tenantName\n"
            "Room: $roomNumber\n"
            "Invoice: $invoiceNo\n"
            "Total Due: $amountStr\n"
            "${dueDateStr.isNotEmpty ? 'Due Date: $dueDateStr\n' : ''}"
            "Status: UNPAID\n\n"
            "Please complete payment on time. Thank you!";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: AppColors.accentOrange, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'alert_tenant'.tr,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                        ),
                        Text(
                          isKh
                              ? "ផ្ញើសាររំលឹកបង់ប្រាក់ទៅកាន់អ្នកជួលតាមជម្រើសខាងក្រោម"
                              : "Send payment reminder to tenant through:",
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
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
              const SizedBox(height: 12),

              // Summary Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primarySoft,
                      child: Text(
                        tenantName.isNotEmpty ? tenantName.substring(0, 1) : "T",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tenantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(
                            "${'room_label_prefix'.tr} $roomNumber • $invoiceNo${phone != null && phone.isNotEmpty ? ' • $phone' : ''}",
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      amountStr,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.accentOrange),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Channel 1: In-App Notification (Instant)
              _buildAlertOptionItem(
                icon: Icons.notifications_rounded,
                iconColor: AppColors.primary,
                bgColor: AppColors.primarySoft,
                title: 'send_in_app_alert'.tr,
                subtitle: isKh
                    ? "ផ្ញើការជូនដំណឹងទៅក្នុងកណ្តឹង App របស់អ្នកជួលភ្លាមៗ"
                    : "Push instant alert to tenant's in-app notification center",
                badgeText: isKh ? "រហ័ស" : "Fast",
                onTap: () {
                  controller.alertTenantForInvoice(inv);
                  Navigator.pop(ctx);
                  Get.snackbar(
                    'notifications'.tr,
                    'alert_sent_success'.trParams({'name': tenantName}),
                    backgroundColor: Colors.white,
                    icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                    margin: const EdgeInsets.all(16),
                  );
                },
              ),

              const SizedBox(height: 8),

              // Channel 2: Telegram Reminder
              _buildAlertOptionItem(
                icon: Icons.send_rounded,
                iconColor: AppColors.accentBlue,
                bgColor: AppColors.accentBlue.withValues(alpha: 0.12),
                title: 'send_telegram_alert'.tr,
                subtitle: isKh
                    ? "ផ្ញើសាររំលឹកបង់ប្រាក់លម្អិតតាម Telegram"
                    : "Send rich payment reminder via Telegram",
                badgeText: "Telegram",
                onTap: () {
                  Navigator.pop(ctx);
                  UrlService.sendInvoiceToTelegram(
                    tenantName: tenantName,
                    roomNumber: roomNumber,
                    totalAmount: inv.totalAmount ?? 0.0,
                    invoiceNo: inv.invoiceNo,
                    dueDate: inv.dueDate,
                  );
                },
              ),

              const SizedBox(height: 8),

              // Channel 3: SMS Reminder
              _buildAlertOptionItem(
                icon: Icons.sms_outlined,
                iconColor: Colors.deepPurple,
                bgColor: Colors.deepPurple.withValues(alpha: 0.12),
                title: 'send_sms_alert'.tr,
                subtitle: phone != null && phone.isNotEmpty
                    ? (isKh ? "ផ្ញើសារ SMS ទៅកាន់លេខ $phone" : "Send SMS text to $phone")
                    : (isKh ? "ផ្ញើសារ SMS ទៅលេខទូរស័ព្ទរបស់អ្នកជួល" : "Send SMS to tenant's phone"),
                badgeText: "SMS",
                onTap: () {
                  Navigator.pop(ctx);
                  if (phone != null && phone.isNotEmpty) {
                    UrlService.sendSms(phoneNumber: phone, message: reminderText);
                  } else {
                    Clipboard.setData(ClipboardData(text: reminderText));
                    Get.snackbar(
                      'send_sms_alert'.tr,
                      isKh
                          ? "មិនទាន់មានលេខទូរស័ព្ទអ្នកជួលទេ អត្ថបទរំលឹកត្រូវបានចម្លងទុក"
                          : "Tenant has no phone registered. Message copied to clipboard.",
                      backgroundColor: Colors.white,
                      margin: const EdgeInsets.all(16),
                    );
                  }
                },
              ),

              const SizedBox(height: 8),

              // Channel 4: Copy Message
              _buildAlertOptionItem(
                icon: Icons.copy_rounded,
                iconColor: AppColors.textPrimary,
                bgColor: AppColors.border.withValues(alpha: 0.5),
                title: 'copy_reminder_msg'.tr,
                subtitle: isKh
                    ? "ចម្លងសាររំលឹកដើម្បីផ្ញើតាម Messenger ឬបណ្ដាញផ្សេងទៀត"
                    : "Copy formatted text to share via Messenger or other apps",
                badgeText: null,
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: reminderText));
                  Get.snackbar(
                    'copy_reminder_msg'.tr,
                    'msg_copied'.tr,
                    backgroundColor: Colors.white,
                    icon: const Icon(Icons.check_circle_outline, color: AppColors.primary),
                    margin: const EdgeInsets.all(16),
                  );
                },
              ),

              if (phone != null && phone.isNotEmpty) ...[
                const SizedBox(height: 8),
                // Channel 5: Direct Phone Call
                _buildAlertOptionItem(
                  icon: Icons.phone_in_talk_rounded,
                  iconColor: AppColors.primary,
                  bgColor: AppColors.primarySoft,
                  title: "${'call_tenant'.tr}: $phone",
                  subtitle: isKh ? "ចុចដើម្បីខលទូរស័ព្ទទៅកាន់អ្នកជួលផ្ទាល់" : "Tap to place a direct phone call",
                  badgeText: isKh ? "ខល" : "Call",
                  onTap: () {
                    Navigator.pop(ctx);
                    UrlService.makePhoneCall(phone);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertOptionItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                      if (badgeText != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: iconColor),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchAlertBanner() {
    final count = controller.unpaidCount;
    final isKh = LanguageService.isKhmer;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentOrange.withValues(alpha: 0.12),
            AppColors.accentOrangeLight.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_active_rounded, color: AppColors.accentOrange, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isKh
                      ? "រំលឹកអ្នកជួលមិនទាន់បង់ប្រាក់ ($count)"
                      : "Alert Unpaid Tenants ($count)",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accentOrange),
                ),
                const SizedBox(height: 2),
                Text(
                  isKh
                      ? "ផ្ញើសាររំលឹកបង់ប្រាក់ទៅកាន់អ្នកជួលមិនទាន់បង់ទាំងអស់"
                      : "Send payment reminders to all unpaid tenants",
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _confirmBatchAlertAllUnpaid,
            icon: const Icon(Icons.send_rounded, size: 13),
            label: Text(
              isKh ? "រំលឹកទាំងអស់" : "Alert All",
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmBatchAlertAllUnpaid() {
    final count = controller.unpaidCount;
    if (count == 0) return;

    AppCleanDialog.showConfirmation(
      context: context,
      title: 'alert_all_tenants_title'.tr,
      message: 'alert_all_confirm_msg'.trParams({'count': count.toString()}),
      confirmText: LanguageService.isKhmer ? "ផ្ញើរំលឹក" : "Send Alerts",
      confirmColor: AppColors.accentOrange,
      onConfirm: () {
        final alertedCount = controller.alertAllUnpaidTenants();
        Get.snackbar(
          'notifications'.tr,
          'alert_all_sent_success'.trParams({'count': alertedCount.toString()}),
          backgroundColor: Colors.white,
          icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
          margin: const EdgeInsets.all(16),
        );
      },
    );
  }

  void _confirmDeleteInvoice(InvoiceModel inv, {VoidCallback? onDeleted}) {
    AppCleanDialog.showConfirmation(
      context: context,
      title: LanguageService.isKhmer ? "លុបវិក្កយបត្រ" : "Delete Invoice",
      message: LanguageService.isKhmer
          ? "តើអ្នកពិតជាចង់លុបវិក្កយបត្រ ${inv.invoiceNo ?? ''} នេះមែនទេ? សកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ។"
          : "Are you sure you want to delete invoice ${inv.invoiceNo ?? ''}? This action cannot be undone.",
      confirmText: LanguageService.isKhmer ? "លុប" : "Delete",
      confirmColor: AppColors.danger,
      onConfirm: () {
        controller.deleteInvoice(inv.id);
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
                    _buildInvoiceRow(
                      'electricity_fee_item'.tr,
                      (inv.oldElectricityReading != null && inv.newElectricityReading != null)
                          ? "${inv.newElectricityReading!.toInt()} - ${inv.oldElectricityReading!.toInt()} = ${inv.electricityUnits?.toStringAsFixed(1) ?? '0'} kWh"
                          : "${inv.electricityUnits ?? 0} kWh",
                      "\$${((inv.electricityUnits ?? 0) * (inv.electricityRate ?? 0.25)).toStringAsFixed(2)}",
                      Icons.bolt_outlined,
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _buildInvoiceRow(
                      'water_fee_item'.tr,
                      (inv.oldWaterReading != null && inv.newWaterReading != null)
                          ? "${inv.newWaterReading!.toInt()} - ${inv.oldWaterReading!.toInt()} = ${inv.waterUnits?.toStringAsFixed(1) ?? '0'} m³"
                          : "${inv.waterUnits ?? 0} m³",
                      "\$${((inv.waterUnits ?? 0) * (inv.waterRate ?? 0.35)).toStringAsFixed(2)}",
                      Icons.water_drop_outlined,
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _buildInvoiceRow(
                      'garbage_fee_item'.tr,
                      LanguageService.isKhmer ? "1 ខែ" : "1 mo",
                      "\$${(inv.garbageFee ?? 2.0).toStringAsFixed(2)}",
                      Icons.delete_outline,
                    ),
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
                          invoiceNo: inv.invoiceNo,
                          dueDate: inv.dueDate,
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
              Builder(
                builder: (context) {
                  final uninvoicedCount = tenants.where((t) => !controller.hasInvoiceForTenantInMonth(
                    roomNumber: t.roomNumber ?? '',
                    tenantName: t.name,
                    date: now,
                  )).length;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                  "$uninvoicedCount / ${tenants.length}",
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                                Text(
                                  LanguageService.isKhmer ? "ត្រូវចេញវិក្កយបត្រ" : "To Invoice",
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
                            final alreadyInvoiced = controller.hasInvoiceForTenantInMonth(
                              roomNumber: t.roomNumber ?? '',
                              tenantName: t.name,
                              date: now,
                            );

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
                                  if (alreadyInvoiced) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.green.shade200),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle_rounded, size: 13, color: Colors.green),
                                          const SizedBox(width: 4),
                                          Text(
                                            LanguageService.isKhmer ? "មានរួចហើយ" : "Invoiced",
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      "\$${rent.toStringAsFixed(0)}/mo",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                    ),
                                  ],
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
                          onPressed: uninvoicedCount == 0 ? null : () {
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
                            uninvoicedCount == 0
                                ? (LanguageService.isKhmer ? "អ្នកជួលទាំងអស់មានវិក្កយបត្ររួចរាល់" : "All Tenants Invoiced")
                                : (LanguageService.isKhmer ? "ចេញវិក្កយបត្រ ($uninvoicedCount នាក់)" : "Generate Invoices ($uninvoicedCount)"),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.grey.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              )
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

    // Load effective utility rates from Settings / Storage
    final rates = controller.getEffectiveRates();
    final double elecRate = rates['electricityRate'] ?? 0.25;
    final double waterRate = rates['waterRate'] ?? 0.35;
    final double garbageDefault = rates['garbageFee'] ?? 2.00;
    final double elecRawKhr = rates['electricityRaw'] ?? 1000.0;
    final double waterRawKhr = rates['waterRaw'] ?? 1500.0;
    final double exRate = rates['exchangeRate'] ?? 4100.0;

    final tenantCtrl = TextEditingController(text: currentTenantName);
    final roomCtrl = TextEditingController(text: currentRoomNumber);
    final rentCtrl = TextEditingController(text: defaultRent.toStringAsFixed(2));
    final garbageCtrl = TextEditingController(text: garbageDefault.toStringAsFixed(2));

    // Meter reading mode: true = Old vs New meter reading (Calculates automatically)
    // false = Direct units entry
    bool isMeterMode = true;

    // Meter controllers
    final oldElecCtrl = TextEditingController();
    final newElecCtrl = TextEditingController();
    final oldWaterCtrl = TextEditingController();
    final newWaterCtrl = TextEditingController();

    // Direct units controllers
    final directElecCtrl = TextEditingController(text: "0.0");
    final directWaterCtrl = TextEditingController(text: "0.0");

    // Populate previous meter readings from previous invoice
    void loadPreviousMeter(String rNum) {
      final lastInv = controller.getLastInvoiceForRoom(rNum);
      final double prevElec = lastInv?.newElectricityReading ?? lastInv?.electricityUnits ?? 0.0;
      final double prevWater = lastInv?.newWaterReading ?? lastInv?.waterUnits ?? 0.0;
      oldElecCtrl.text = prevElec > 0 ? (prevElec.truncateToDouble() == prevElec ? prevElec.toInt().toString() : prevElec.toString()) : "0";
      oldWaterCtrl.text = prevWater > 0 ? (prevWater.truncateToDouble() == prevWater ? prevWater.toInt().toString() : prevWater.toString()) : "0";
      newElecCtrl.clear();
      newWaterCtrl.clear();
    }

    loadPreviousMeter(currentRoomNumber);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          double getElecUnits() {
            if (isMeterMode) {
              final oldE = double.tryParse(oldElecCtrl.text.trim()) ?? 0.0;
              final newE = double.tryParse(newElecCtrl.text.trim());
              if (newE == null) return 0.0;
              return (newE - oldE).clamp(0.0, 999999.0);
            }
            return double.tryParse(directElecCtrl.text.trim()) ?? 0.0;
          }

          double getWaterUnits() {
            if (isMeterMode) {
              final oldW = double.tryParse(oldWaterCtrl.text.trim()) ?? 0.0;
              final newW = double.tryParse(newWaterCtrl.text.trim());
              if (newW == null) return 0.0;
              return (newW - oldW).clamp(0.0, 999999.0);
            }
            return double.tryParse(directWaterCtrl.text.trim()) ?? 0.0;
          }

          final rent = double.tryParse(rentCtrl.text.trim()) ?? 0.0;
          final garbage = double.tryParse(garbageCtrl.text.trim()) ?? 0.0;
          final elecUnits = getElecUnits();
          final waterUnits = getWaterUnits();
          final elecTotal = elecUnits * elecRate;
          final waterTotal = waterUnits * waterRate;
          final grandTotal = rent + elecTotal + waterTotal + garbage;

          return AppCleanDialog(
            title: LanguageService.isKhmer ? "បង្កើតវិក្កយបត្រថ្មី" : "Create New Invoice",
            subtitle: LanguageService.isKhmer
                ? "គណនាថ្លៃបន្ទប់ ទឹក និងភ្លើងដោយស្វ័យប្រវត្តិ"
                : "Automatic room, water & electricity calculation",
            maxWidth: 480,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tenant Selection
                if (tList.isNotEmpty && presetTenant == null) ...[
                  Text(
                    LanguageService.isKhmer ? "ជ្រើសរើសអ្នកជួល" : "Select Tenant",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<TenantModel>(
                    initialValue: selectedTenant,
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
                          loadPreviousMeter(val.roomNumber ?? '');
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

                // Room & Rent Price
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: roomCtrl,
                        decoration: InputDecoration(
                          labelText: 'room_number'.tr,
                          prefixIcon: const Icon(Icons.meeting_room_outlined, color: AppColors.primary, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onChanged: (val) {
                          loadPreviousMeter(val.trim());
                          setDialogState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: TextField(
                        controller: rentCtrl,
                        decoration: InputDecoration(
                          labelText: "${'rent_price_label'.tr} (\$)",
                          prefixIcon: const Icon(Icons.attach_money, color: AppColors.primary, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Calculation Mode Switcher
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => setDialogState(() => isMeterMode = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isMeterMode ? AppColors.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: isMeterMode
                                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.speed_rounded, size: 16, color: isMeterMode ? AppColors.primary : AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  LanguageService.isKhmer ? "គិតតាមលេខកុងទ័រ (ងាយស្រួល)" : "Meter Reading",
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: isMeterMode ? FontWeight.bold : FontWeight.w500,
                                    color: isMeterMode ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => setDialogState(() => isMeterMode = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !isMeterMode ? AppColors.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: !isMeterMode
                                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_note_rounded, size: 16, color: !isMeterMode ? AppColors.primary : AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  LanguageService.isKhmer ? "វាយចំនួនផ្ទាល់" : "Direct Units",
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: !isMeterMode ? FontWeight.bold : FontWeight.w500,
                                    color: !isMeterMode ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Electricity Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bolt, color: Colors.amber, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                "${'electricity_fee_item'.tr} (kWh)",
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          Text(
                            elecRawKhr >= 50
                                ? "${elecRawKhr.round()} ៛/kWh (~\$${elecRate.toStringAsFixed(3)})"
                                : "\$${elecRate.toStringAsFixed(2)} / kWh",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (isMeterMode) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: oldElecCtrl,
                                decoration: InputDecoration(
                                  labelText: LanguageService.isKhmer ? "លេខចាស់ (Old)" : "Old Reading",
                                  prefixIcon: const Icon(Icons.history_rounded, size: 18, color: Colors.grey),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  helperText: LanguageService.isKhmer ? "ស្វ័យប្រវត្តិចុងក្រោយ" : "From last invoice",
                                  helperStyle: const TextStyle(fontSize: 9.5),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setDialogState(() {}),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text("-", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ),
                            Expanded(
                              child: TextField(
                                controller: newElecCtrl,
                                decoration: InputDecoration(
                                  labelText: LanguageService.isKhmer ? "លេខថ្មី (New)" : "New Reading",
                                  prefixIcon: const Icon(Icons.speed_rounded, size: 18, color: Colors.amber),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  helperText: LanguageService.isKhmer ? "កត់កុងទ័រចុងខែ" : "Current meter",
                                  helperStyle: const TextStyle(fontSize: 9.5, color: Colors.amber),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setDialogState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                LanguageService.isKhmer
                                    ? "ប្រើអស់: ${elecUnits.toStringAsFixed(1)} kWh"
                                    : "Used: ${elecUnits.toStringAsFixed(1)} kWh",
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.brown),
                              ),
                              Text(
                                "= \$${elecTotal.toStringAsFixed(2)} (${(elecTotal * exRate).round()} ៛)",
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.brown),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        TextField(
                          controller: directElecCtrl,
                          decoration: InputDecoration(
                            labelText: LanguageService.isKhmer ? "ចំនួនគីឡូភ្លើងប្រើប្រាស់ (kWh)" : "Units Used (kWh)",
                            prefixIcon: const Icon(Icons.bolt, color: Colors.amber, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Water Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.water_drop_outlined, color: Colors.blue, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                "${'water_fee_item'.tr} (m³)",
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          Text(
                            waterRawKhr >= 50
                                ? "${waterRawKhr.round()} ៛/m³ (~\$${waterRate.toStringAsFixed(3)})"
                                : "\$${waterRate.toStringAsFixed(2)} / m³",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (isMeterMode) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: oldWaterCtrl,
                                decoration: InputDecoration(
                                  labelText: LanguageService.isKhmer ? "លេខចាស់ (Old)" : "Old Reading",
                                  prefixIcon: const Icon(Icons.history_rounded, size: 18, color: Colors.grey),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  helperText: LanguageService.isKhmer ? "ស្វ័យប្រវត្តិចុងក្រោយ" : "From last invoice",
                                  helperStyle: const TextStyle(fontSize: 9.5),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setDialogState(() {}),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text("-", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ),
                            Expanded(
                              child: TextField(
                                controller: newWaterCtrl,
                                decoration: InputDecoration(
                                  labelText: LanguageService.isKhmer ? "លេខថ្មី (New)" : "New Reading",
                                  prefixIcon: const Icon(Icons.water_drop_rounded, size: 18, color: Colors.blue),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  helperText: LanguageService.isKhmer ? "កត់កុងទ័រចុងខែ" : "Current meter",
                                  helperStyle: const TextStyle(fontSize: 9.5, color: Colors.blue),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setDialogState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                LanguageService.isKhmer
                                    ? "ប្រើអស់: ${waterUnits.toStringAsFixed(1)} m³"
                                    : "Used: ${waterUnits.toStringAsFixed(1)} m³",
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.indigo),
                              ),
                              Text(
                                "= \$${waterTotal.toStringAsFixed(2)} (${(waterTotal * exRate).round()} ៛)",
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.indigo),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        TextField(
                          controller: directWaterCtrl,
                          decoration: InputDecoration(
                            labelText: LanguageService.isKhmer ? "ចំនួនម៉ែត្រគូបទឹកប្រើប្រាស់ (m³)" : "Units Used (m³)",
                            prefixIcon: const Icon(Icons.water_drop_outlined, color: Colors.blue, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Garbage Fee
                TextField(
                  controller: garbageCtrl,
                  decoration: InputDecoration(
                    labelText: LanguageService.isKhmer ? "ថ្លៃសំរាម (\$)" : "Garbage Fee (\$)",
                    prefixIcon: const Icon(Icons.delete_outline, color: AppColors.primary, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setDialogState(() {}),
                ),

                const SizedBox(height: 14),

                // Live Summary Calculation Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('room_rent_fee'.tr, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text("\$${rent.toStringAsFixed(2)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${'electricity_fee_item'.tr} (${elecUnits.toStringAsFixed(1)} kWh)",
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          Text("\$${elecTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${'water_fee_item'.tr} (${waterUnits.toStringAsFixed(1)} m³)",
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          Text("\$${waterTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('garbage_fee_item'.tr, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text("\$${garbage.toStringAsFixed(2)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Divider(height: 1, color: AppColors.border),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            LanguageService.isKhmer ? "ទឹកប្រាក់សរុប (Total Due):" : "Total Due:",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "\$${grandTotal.toStringAsFixed(2)}",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                              Text(
                                "~${(grandTotal * exRate).round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ៛",
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            confirmText: LanguageService.isKhmer ? "បង្កើតវិក្កយបត្រ" : "Create Invoice",
            cancelText: 'cancel'.tr,
            onConfirm: () {
              final tenantName = tenantCtrl.text.trim();
              final roomNumber = roomCtrl.text.trim();
              if (tenantName.isEmpty || roomNumber.isEmpty) {
                Get.snackbar('error'.tr, LanguageService.isKhmer ? 'សូមបញ្ចូលឈ្មោះ និងលេខបន្ទប់' : 'Please enter name and room number', backgroundColor: Colors.red.shade50);
                return;
              }

              final rent = double.tryParse(rentCtrl.text.trim()) ?? defaultRent;
              final garbage = double.tryParse(garbageCtrl.text.trim()) ?? garbageDefault;
              final elecUnits = getElecUnits();
              final waterUnits = getWaterUnits();
              final elecTotal = elecUnits * elecRate;
              final waterTotal = waterUnits * waterRate;
              final total = rent + elecTotal + waterTotal + garbage;

              final now = DateTime.now();
              final cleanRoom = roomNumber.replaceAll(' ', '');
              final invNo = "INV-${now.year}${now.month.toString().padLeft(2, '0')}-$cleanRoom";

              final double? oldElec = isMeterMode ? double.tryParse(oldElecCtrl.text.trim()) : null;
              final double? newElec = isMeterMode ? double.tryParse(newElecCtrl.text.trim()) : null;
              final double? oldWater = isMeterMode ? double.tryParse(oldWaterCtrl.text.trim()) : null;
              final double? newWater = isMeterMode ? double.tryParse(newWaterCtrl.text.trim()) : null;

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
                electricityUnits: elecUnits,
                electricityRate: elecRate,
                waterUnits: waterUnits,
                waterRate: waterRate,
                garbageFee: garbage,
                totalAmount: total,
                status: "UNPAID",
                oldElectricityReading: oldElec,
                newElectricityReading: newElec,
                oldWaterReading: oldWater,
                newWaterReading: newWater,
              );

              final existing = controller.getExistingInvoiceForMonth(
                roomNumber: roomNumber,
                tenantName: tenantName,
                date: now,
              );

              controller.createInvoice(newInv, overwriteExisting: true);
              Navigator.pop(ctx);
              if (existing != null) {
                Get.snackbar(
                  'success'.tr,
                  LanguageService.isKhmer
                      ? "បានកែប្រែវិក្កយបត្រខែនេះសម្រាប់បន្ទប់ $roomNumber រួចរាល់ (${newInv.invoiceNo} - \$${total.toStringAsFixed(2)})"
                      : "Updated existing invoice for Room $roomNumber (${newInv.invoiceNo} - \$${total.toStringAsFixed(2)})",
                  backgroundColor: Colors.green.shade50,
                  icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                );
              } else {
                Get.snackbar(
                  'success'.tr,
                  "${newInv.invoiceNo} - \$${total.toStringAsFixed(2)}",
                  backgroundColor: Colors.green.shade50,
                  icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                );
              }
            },
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

              // Search Bar for Tenants / Rooms / Invoices
              _buildSearchBar(),

              // Filter Tabs & Date Filter Button
              Row(
                children: [
                  _buildFilterTab("ALL", 'all'.tr, controller.selectedFilter.value),
                  const SizedBox(width: 6),
                  _buildFilterTab("UNPAID", 'unpaid_status'.tr, controller.selectedFilter.value),
                  const SizedBox(width: 6),
                  _buildFilterTab("PAID", 'paid_status'.tr, controller.selectedFilter.value),
                  const Spacer(),
                  _buildDateFilterButton(),
                ],
              ),

              // Active Tenant / Search Filter Banner
              _buildActiveTenantFilterBanner(),

              // Active Date Filter Banner if filtered
              if (controller.isDateFilterActive) ...[
                const SizedBox(height: 8),
                _buildActiveDateFilterChip(),
              ],

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
                            controller.isSearchActive
                                ? (LanguageService.isKhmer
                                    ? "មិនមានវិក្កយបត្រត្រូវនឹង '${controller.selectedTenantFilter.value ?? controller.searchQuery.value}' ទេ"
                                    : "No invoices match '${controller.selectedTenantFilter.value ?? controller.searchQuery.value}'")
                                : 'no_invoices_found'.tr,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                          if (controller.isSearchActive) ...[
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                controller.clearSearch();
                                _resetPagination();
                              },
                              icon: const Icon(Icons.clear_all_rounded, size: 16),
                              label: Text(LanguageService.isKhmer ? "សម្អាតការស្វែងរក" : "Clear Search"),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
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

  Widget _buildDateFilterButton() {
    final isActive = controller.isDateFilterActive;
    return InkWell(
      onTap: _showDateFilterSheet,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
            width: isActive ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 15,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              controller.dateFilterLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            if (isActive)
              GestureDetector(
                onTap: () {
                  controller.clearDateFilter();
                  _resetPagination();
                },
                child: const Padding(
                  padding: EdgeInsets.only(left: 2),
                  child: Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
                ),
              )
            else
              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveDateFilterChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_outlined, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              LanguageService.isKhmer
                  ? "កំពុងចម្រាញ់តាមកាលបរិច្ឆេទ: ${controller.dateFilterLabel} (${controller.filteredInvoices.length} វិក្កយបត្រ)"
                  : "Filtered by date: ${controller.dateFilterLabel} (${controller.filteredInvoices.length} invoices)",
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
          InkWell(
            onTap: () {
              controller.clearDateFilter();
              _resetPagination();
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.close_rounded, size: 13, color: AppColors.primary),
                  const SizedBox(width: 2),
                  Text(
                    LanguageService.isKhmer ? "សម្អាត" : "Clear",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isKh = LanguageService.isKhmer;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          controller.searchQuery.value = val;
          if (controller.selectedTenantFilter.value != null && val != controller.selectedTenantFilter.value) {
            controller.selectedTenantFilter.value = null;
          }
          _resetPagination();
        },
        decoration: InputDecoration(
          hintText: isKh ? "ស្វែងរកអ្នកជួល លេខបន្ទប់ ឬវិក្កយបត្រ..." : "Search tenant, room or invoice...",
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
          suffixIcon: Obx(() {
            final hasText = controller.searchQuery.value.trim().isNotEmpty || controller.selectedTenantFilter.value != null;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasText)
                  IconButton(
                    tooltip: isKh ? "សម្អាត" : "Clear",
                    icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      controller.clearSearch();
                      _resetPagination();
                    },
                  ),
                IconButton(
                  tooltip: isKh ? "ជ្រើសរើសអ្នកជួល" : "Filter by Tenant",
                  icon: Icon(
                    Icons.people_outline_rounded,
                    size: 20,
                    color: controller.selectedTenantFilter.value != null ? AppColors.primary : AppColors.textSecondary,
                  ),
                  onPressed: _showTenantPickerFilter,
                ),
              ],
            );
          }),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTenantFilterBanner() {
    final isKh = LanguageService.isKhmer;
    return Obx(() {
      final activeTenant = controller.selectedTenantFilter.value;
      final query = controller.searchQuery.value.trim();
      if (activeTenant == null && query.isEmpty) return const SizedBox.shrink();

      final label = activeTenant ?? query;
      final count = controller.filteredInvoices.length;

      return Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_search_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isKh
                    ? "កំពុងបង្ហាញវិក្កយបត្ររបស់៖ $label ($count វិក្កយបត្រ)"
                    : "Showing invoices for: $label ($count invoices)",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            InkWell(
              onTap: () {
                _searchController.clear();
                controller.clearSearch();
                _resetPagination();
              },
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 16, color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showTenantPickerFilter() {
    final isKh = LanguageService.isKhmer;
    final searchTenantCtrl = TextEditingController();
    final RxString innerQuery = ''.obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SafeArea(
                top: false,
                bottom: true,
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
                          child: const Icon(Icons.people_alt_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isKh ? "ជ្រើសរើសអ្នកជួល" : "Filter Invoices by Tenant",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              Text(
                                isKh ? "បង្ហាញវិក្កយបត្ររបស់អ្នកជួលជាក់លាក់" : "Show invoices belonging to a specific tenant",
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: searchTenantCtrl,
                      onChanged: (val) => innerQuery.value = val,
                      decoration: InputDecoration(
                        hintText: isKh ? "ស្វែងរកឈ្មោះ ឬបន្ទប់..." : "Search tenant name or room...",
                        hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
                      child: Obx(() {
                        final query = innerQuery.value.trim().toLowerCase();
                        final tenants = controller.availableTenants.where((t) {
                          if (query.isEmpty) return true;
                          final name = (t.name ?? '').toLowerCase();
                          final room = (t.roomNumber ?? '').toLowerCase();
                          return name.contains(query) || room.contains(query);
                        }).toList();

                        return ListView(
                          shrinkWrap: true,
                          children: [
                            // Option: All Tenants
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              leading: const CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primarySoft,
                                child: Icon(Icons.people_alt_outlined, size: 18, color: AppColors.primary),
                              ),
                              title: Text(
                                isKh ? "អ្នកជួលទាំងអស់ (បង្ហាញទាំងអស់)" : "All Tenants (Show All)",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              subtitle: Text(
                                "${controller.invoices.length} ${isKh ? 'វិក្កយបត្រសរុប' : 'total invoices'}",
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              trailing: controller.selectedTenantFilter.value == null && controller.searchQuery.value.isEmpty
                                  ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                                  : null,
                              onTap: () {
                                _searchController.clear();
                                controller.clearSearch();
                                _resetPagination();
                                Navigator.pop(ctx);
                              },
                            ),
                            const Divider(height: 1, color: AppColors.border),
                            ...tenants.map((t) {
                              final count = controller.getInvoiceCountForTenant(t.name ?? '');
                              final unpaid = controller.getUnpaidAmountForTenant(t.name ?? '');
                              final isSelected = controller.selectedTenantFilter.value == t.name;

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isSelected ? AppColors.primary : AppColors.primarySoft,
                                  child: Text(
                                    (t.name != null && t.name!.isNotEmpty) ? t.name!.substring(0, 1).toUpperCase() : "T",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isSelected ? Colors.white : AppColors.primary,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  "${t.name ?? 'Tenant'} (${'room_label_prefix'.tr} ${t.roomNumber ?? ''})",
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 13.5,
                                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  unpaid > 0
                                      ? "$count ${isKh ? 'វិក្កយបត្រ' : 'invoices'} • ${isKh ? 'ជំពាក់' : 'Due'}: \$${unpaid.toStringAsFixed(2)}"
                                      : "$count ${isKh ? 'វិក្កយបត្រ' : 'invoices'} • ${isKh ? 'បានទូទាត់អស់' : 'Paid up'}",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: unpaid > 0 ? AppColors.accentOrange : AppColors.textSecondary,
                                    fontWeight: unpaid > 0 ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                                    : const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
                                onTap: () {
                                  _searchController.text = t.name ?? '';
                                  controller.setTenantFilter(t.name);
                                  _resetPagination();
                                  Navigator.pop(ctx);
                                },
                              );
                            }),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDateFilterSheet() {
    final now = DateTime.now();
    final isKh = LanguageService.isKhmer;
    final currentType = controller.selectedDateFilterType.value;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppColors.surface,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top drag indicator
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

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isKh ? "ចម្រាញ់តាមកាលបរិច្ឆេទ" : "Filter by Date",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              isKh ? "ជ្រើសរើសខែ ឬចន្លោះកាលបរិច្ឆេទសម្រាប់វិក្កយបត្រ" : "Select month or date range for invoices",
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 8),

                  // Option: All Dates
                  _buildDateOptionTile(
                    title: isKh ? "កាលបរិច្ឆេទទាំងអស់" : "All Dates",
                    subtitle: "${controller.invoices.length} ${isKh ? 'វិក្កយបត្រសរុប' : 'total invoices'}",
                    icon: Icons.all_inclusive_rounded,
                    isSelected: currentType == "ALL",
                    onTap: () {
                      controller.clearDateFilter();
                      _resetPagination();
                      Navigator.pop(ctx);
                    },
                  ),

                  // Option: This Month
                  _buildDateOptionTile(
                    title: isKh ? "ខែនេះ" : "This Month",
                    subtitle: isKh
                        ? "ខែ ${['មករា', 'កុម្ភៈ', 'មីនា', 'មេសា', 'ឧសភា', 'មិថុនា', 'កក្កដា', 'សីហា', 'កញ្ញា', 'តុលា', 'វិច្ឆិកា', 'ធ្នូ'][now.month - 1]} ${now.year} • ${controller.getInvoiceCountForDateFilter('THIS_MONTH')} វិក្កយបត្រ"
                        : "${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][now.month - 1]} ${now.year} • ${controller.getInvoiceCountForDateFilter('THIS_MONTH')} invoices",
                    icon: Icons.calendar_today_rounded,
                    isSelected: currentType == "THIS_MONTH",
                    onTap: () {
                      controller.setDateFilterType("THIS_MONTH");
                      _resetPagination();
                      Navigator.pop(ctx);
                    },
                  ),

                  // Option: Last Month
                  _buildDateOptionTile(
                    title: isKh ? "ខែមុន" : "Last Month",
                    subtitle: isKh
                        ? "ខែ ${['មករា', 'កុម្ភៈ', 'មីនា', 'មេសា', 'ឧសភា', 'មិថុនា', 'កក្កដា', 'សីហា', 'កញ្ញា', 'តុលា', 'វិច្ឆិកា', 'ធ្នូ'][(now.month - 2 + 12) % 12]} • ${controller.getInvoiceCountForDateFilter('LAST_MONTH')} វិក្កយបត្រ"
                        : "${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][(now.month - 2 + 12) % 12]} • ${controller.getInvoiceCountForDateFilter('LAST_MONTH')} invoices",
                    icon: Icons.history_rounded,
                    isSelected: currentType == "LAST_MONTH",
                    onTap: () {
                      controller.setDateFilterType("LAST_MONTH");
                      _resetPagination();
                      Navigator.pop(ctx);
                    },
                  ),

                  // Option: Today
                  _buildDateOptionTile(
                    title: isKh ? "ថ្ងៃនេះ" : "Today",
                    subtitle: "${controller.getInvoiceCountForDateFilter('TODAY')} ${isKh ? 'វិក្កយបត្រ' : 'invoices'}",
                    icon: Icons.today_rounded,
                    isSelected: currentType == "TODAY",
                    onTap: () {
                      controller.setDateFilterType("TODAY");
                      _resetPagination();
                      Navigator.pop(ctx);
                    },
                  ),

                  const Divider(height: 14, color: AppColors.border),

                  // Option: Pick Specific Date
                  _buildDateOptionTile(
                    title: isKh ? "ជ្រើសរើសថ្ងៃជាក់លាក់..." : "Pick a Specific Date...",
                    subtitle: currentType == "CUSTOM_DATE" && controller.selectedCustomDate.value != null
                        ? (isKh
                            ? "បានជ្រើស: ${controller.selectedCustomDate.value!.day}/${controller.selectedCustomDate.value!.month}/${controller.selectedCustomDate.value!.year}"
                            : "Selected: ${controller.selectedCustomDate.value!.day}/${controller.selectedCustomDate.value!.month}/${controller.selectedCustomDate.value!.year}")
                        : (isKh ? "ជ្រើសរើសថ្ងៃណាមួយពីប្រតិទិន" : "Pick any day from calendar"),
                    icon: Icons.event_available_rounded,
                    isSelected: currentType == "CUSTOM_DATE",
                    onTap: () async {
                      Navigator.pop(ctx);
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: controller.selectedCustomDate.value ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(primary: AppColors.primary),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        controller.setCustomDate(picked);
                        _resetPagination();
                      }
                    },
                  ),

                  // Option: Pick Date Range
                  _buildDateOptionTile(
                    title: isKh ? "ជ្រើសរើសចន្លោះកាលបរិច្ឆេទ..." : "Pick Date Range...",
                    subtitle: currentType == "CUSTOM_RANGE" && controller.selectedCustomRange.value != null
                        ? "${controller.selectedCustomRange.value!.start.day}/${controller.selectedCustomRange.value!.start.month} - ${controller.selectedCustomRange.value!.end.day}/${controller.selectedCustomRange.value!.end.month}/${controller.selectedCustomRange.value!.end.year}"
                        : (isKh ? "ជ្រើសរើសថ្ងៃចាប់ផ្ដើម និងថ្ងៃបញ្ចប់" : "Pick start and end dates"),
                    icon: Icons.date_range_rounded,
                    isSelected: currentType == "CUSTOM_RANGE",
                    onTap: () async {
                      Navigator.pop(ctx);
                      final pickedRange = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        initialDateRange: controller.selectedCustomRange.value ?? DateTimeRange(
                          start: DateTime.now().subtract(const Duration(days: 30)),
                          end: DateTime.now(),
                        ),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(primary: AppColors.primary),
                          ),
                          child: child!,
                        ),
                      );
                      if (pickedRange != null) {
                        controller.setCustomDateRange(pickedRange);
                        _resetPagination();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft.withValues(alpha: 0.6) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.8) : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
          ],
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
