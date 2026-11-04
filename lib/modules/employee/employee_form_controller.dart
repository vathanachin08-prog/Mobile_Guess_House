import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/employee/employee_model.dart';
import '../../repositories/employee_repository.dart';
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
        Get.snackbar(
          'Updated',
          '${employeeData.name} updated successfully',
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade900,
          icon: Icon(Icons.check_circle_rounded, color: Colors.green.shade600),
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      } else {
        await repository.createEmployee(employeeData);
        Get.snackbar(
          'Created',
          '${employeeData.name} added successfully',
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade900,
          icon: Icon(Icons.check_circle_rounded, color: Colors.green.shade600),
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }

      Get.back(result: true);
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
}

