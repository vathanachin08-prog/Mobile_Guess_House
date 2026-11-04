import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/employee/employee_model.dart';
import '../../repositories/employee_repository.dart';
import '../../routes/app_route_name.dart';
import '../../widgets/app_colors.dart';
import 'employee_controller.dart';

class EmployeeFormController extends GetxController {
  final EmployeeRepository repository;

  EmployeeFormController({required this.repository});

  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final positionController = TextEditingController();
  final salaryController = TextEditingController();
  final departmentController = TextEditingController();

  final selectedDepartment = ''.obs;
  final departments = <String>[].obs;

  final isEditing = false.obs;
  dynamic editingId;
  final isSaving = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();

    // Pull existing departments dynamically from live employee database
    if (Get.isRegistered<EmployeeController>()) {
      final empCtrl = Get.find<EmployeeController>();
      final depts = empCtrl.departments.where((d) => d != 'All').toList();
      departments.assignAll(depts);
    }

    final args = Get.arguments;
    if (args is EmployeeModel) {
      isEditing.value = true;
      editingId = args.id;
      nameController.text = args.name;
      emailController.text = args.email;
      phoneController.text = args.phone;
      positionController.text = args.position;
      salaryController.text = args.salary.toString();
      departmentController.text = args.department;
      if (!departments.contains(args.department) && args.department.isNotEmpty) {
        departments.add(args.department);
      }
      selectedDepartment.value = args.department;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    positionController.dispose();
    salaryController.dispose();
    departmentController.dispose();
    super.onClose();
  }

  // --- Field Validators ---

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Employee name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleanPhone.length < 8 || !RegExp(r'^\d+$').hasMatch(cleanPhone)) {
      return 'Enter a valid phone number (at least 8 digits)';
    }
    return null;
  }

  String? validatePosition(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Position is required';
    }
    return null;
  }

  String? validateSalary(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Salary is required';
    }
    final num = double.tryParse(value.trim());
    if (num == null || num < 0) {
      return 'Enter a valid positive number';
    }
    return null;
  }

  // --- Submit Action ---

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isSaving.value = true;
    errorMessage.value = '';

    final employeeData = EmployeeModel(
      id: editingId,
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
      position: positionController.text.trim(),
      department: departmentController.text.trim().isNotEmpty
          ? departmentController.text.trim()
          : selectedDepartment.value,
      salary: double.tryParse(salaryController.text.trim()) ?? 0.0,
      status: 'ACT',
    );

    try {
      if (isEditing.value) {
        await repository.updateEmployee(editingId, employeeData);
        await _showSuccessDialog(
          isUpdate: true,
          employee: employeeData,
        );
      } else {
        await repository.createEmployee(employeeData);
        await _showSuccessDialog(
          isUpdate: false,
          employee: employeeData,
        );
      }
    } catch (e) {
      errorMessage.value = 'Failed to save employee: $e';
      Get.snackbar(
        'Error',
        errorMessage.value,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  /// Displays a clear modal dialog when save/update succeeds,
  /// then redirects the user to the employee view upon confirmation.
  Future<void> _showSuccessDialog({
    required bool isUpdate,
    required EmployeeModel employee,
  }) async {
    await Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                isUpdate ? 'Update Successful' : 'Employee Added',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                  children: [
                    TextSpan(
                      text: isUpdate
                          ? 'The information for '
                          : 'New record for ',
                    ),
                    TextSpan(
                      text: employee.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    TextSpan(
                      text: isUpdate
                          ? ' was updated successfully in the database.'
                          : ' was saved successfully to the database.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Summary Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primarySoft,
                      radius: 20,
                      child: Text(
                        employee.initials,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${employee.position} • ${employee.department}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            employee.formattedSalary,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (isUpdate)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(), // Closes dialog, stays on form
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          'Keep Editing',
                          style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  if (isUpdate) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back(); // close dialog
                        _redirectToEmployeeList();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _redirectToEmployeeList() {
    if (Get.isRegistered<EmployeeController>()) {
      Get.find<EmployeeController>().fetchEmployees();
    }
    if (Navigator.canPop(Get.context!)) {
      Get.back(result: true);
    } else {
      Get.offAllNamed(AppRouteName.portal);
    }
  }
}
