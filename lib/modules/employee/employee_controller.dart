import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/employee/employee_model.dart';
import '../../repositories/employee_repository.dart';
import '../../routes/app_route_name.dart';
import '../../widgets/app_colors.dart';

class EmployeeController extends GetxController {
  final EmployeeRepository repository;

  EmployeeController({required this.repository});

  final employees = <EmployeeModel>[].obs;
  final filteredEmployees = <EmployeeModel>[].obs;
  final isLoading = false.obs;
  final isDeleting = false.obs;
  final searchQuery = ''.obs;
  final selectedDepartment = 'All'.obs;
  final departments = <String>['All', 'Engineering', 'Design', 'Product', 'Quality Assurance', 'Infrastructure', 'HR', 'Marketing'].obs;
  final errorMessage = ''.obs;

  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchEmployees();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchEmployees() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await repository.getEmployees();
      employees.assignAll(result);
      applyFilter();
    } catch (e) {
      errorMessage.value = 'Failed to load employees: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    applyFilter();
  }

  void onDepartmentSelected(String dept) {
    selectedDepartment.value = dept;
    applyFilter();
  }

  void applyFilter() {
    final query = searchQuery.value.trim().toLowerCase();
    final dept = selectedDepartment.value;

    filteredEmployees.assignAll(
      employees.where((emp) {
        final matchesSearch = query.isEmpty ||
            emp.name.toLowerCase().contains(query) ||
            emp.position.toLowerCase().contains(query) ||
            emp.email.toLowerCase().contains(query) ||
            emp.department.toLowerCase().contains(query);

        final matchesDept = dept == 'All' || emp.department.toLowerCase() == dept.toLowerCase();

        return matchesSearch && matchesDept;
      }).toList(),
    );
  }

  void navigateToAdd() async {
    final result = await Get.toNamed(AppRouteName.employeeForm);
    if (result == true) {
      fetchEmployees();
    }
  }

  void navigateToEdit(EmployeeModel employee) async {
    final result = await Get.toNamed(AppRouteName.employeeForm, arguments: employee);
    if (result == true) {
      fetchEmployees();
    }
  }

  void confirmDelete(BuildContext context, EmployeeModel employee) {
    Get.dialog(
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
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_forever_rounded, color: Colors.red.shade600, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete Employee',
                style: TextStyle(
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
                    const TextSpan(text: 'Are you sure you want to delete\n'),
                    TextSpan(
                      text: employee.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const TextSpan(text: '? This action cannot be undone.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text('Cancel', style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back(); // close dialog
                        await deleteEmployee(employee);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> deleteEmployee(EmployeeModel employee) async {
    isDeleting.value = true;
    try {
      final success = await repository.deleteEmployee(employee.id);
      if (success) {
        employees.removeWhere((e) => e.id.toString() == employee.id.toString());
        applyFilter();
        Get.snackbar(
          'Deleted',
          '${employee.name} was successfully removed',
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade900,
          icon: Icon(Icons.check_circle_rounded, color: Colors.red.shade600),
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to delete employee',
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade900,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete: $e',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade900,
      );
    } finally {
      isDeleting.value = false;
    }
  }
}

