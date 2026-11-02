import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/constant_uri.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../widgets/app_clean_dialog.dart';
import '../../../widgets/app_colors.dart';
import '../home/student_home_controller.dart';
import 'visit_requests_controller.dart';

class RequestVisitDialog extends StatefulWidget {
  final int propertyId;
  final int? roomId;
  final String? roomNumber;
  final String propertyName;

  const RequestVisitDialog({
    super.key,
    required this.propertyId,
    this.roomId,
    this.roomNumber,
    required this.propertyName,
  });

  @override
  State<RequestVisitDialog> createState() => _RequestVisitDialogState();
}

class _RequestVisitDialogState extends State<RequestVisitDialog> {
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = const TimeOfDay(hour: 14, minute: 30);
  final phoneController = TextEditingController(text: "012345678");
  final noteController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void _submit() async {
    final phone = phoneController.text.trim();
    final formattedDate = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    final formattedTime = "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";

    if (phone.isEmpty) {
      AppFirebaseService.logVisitRequestForm(
        propertyId: widget.propertyId,
        roomId: widget.roomId,
        requestedDate: formattedDate,
        success: false,
        errorMessage: "Validation: Empty phone number",
      );
      Get.snackbar("Error", "Please provide a contact phone number");
      return;
    }

    setState(() => isLoading = true);

    try {
      final api = Get.find<ApiService>();
      final notes = noteController.text.trim();
      final fullMessage = notes.isNotEmpty
          ? "$notes (Phone: $phone)"
          : "Interested in visiting (Phone: $phone)";

      final body = {
        "propertyId": widget.propertyId,
        if (widget.roomId != null) "roomId": widget.roomId,
        "requestedDate": formattedDate,
        "requestedTime": formattedTime,
        "message": fullMessage,
      };

      final res = await api.postApi(ConstantUri.visitRequests, body: body);
      if (res != null) {
        AppFirebaseService.logVisitRequestForm(
          propertyId: widget.propertyId,
          roomId: widget.roomId,
          requestedDate: formattedDate,
          success: true,
        );

        if (Get.isRegistered<VisitRequestsController>()) {
          Get.find<VisitRequestsController>().loadRequests();
        }
        if (Get.isRegistered<StudentHomeController>()) {
          Get.find<StudentHomeController>().loadNotifications();
        }

        Get.back();
        Get.snackbar(
          "Success",
          "ស្នើសុំកាលវិភាគមើលបន្ទប់ជោគជ័យ! Visit request submitted.",
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade900,
        );
      } else {
        AppFirebaseService.logVisitRequestForm(
          propertyId: widget.propertyId,
          roomId: widget.roomId,
          requestedDate: formattedDate,
          success: false,
          errorMessage: "API error: submission returned null",
        );
        Get.snackbar("Error", "Could not submit visit request");
      }
    } catch (e) {
      AppFirebaseService.logVisitRequestForm(
        propertyId: widget.propertyId,
        roomId: widget.roomId,
        requestedDate: formattedDate,
        success: false,
        errorMessage: e.toString(),
      );
      Get.snackbar("Error", "Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCleanDialog(
      title: 'book_visit'.tr,
      subtitle: "${widget.propertyName}${widget.roomNumber != null ? ' • Room ${widget.roomNumber}' : ''}",
      maxWidth: 420,
      isConfirmLoading: isLoading,
      confirmText: 'confirm'.tr,
      cancelText: 'cancel'.tr,
      onConfirm: _submit,
      onCancel: () => Get.back(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date picker field
          Text('date_label'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) setState(() => selectedDate = picked);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Time picker field
            Text('time_label'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: selectedTime,
                );
                if (picked != null) setState(() => selectedTime = picked);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      selectedTime.format(context),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Contact Phone
            Text('phone_number'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 14),

            // Note
            Text('description_optional'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

        ],
      ),
    );
  }
}
