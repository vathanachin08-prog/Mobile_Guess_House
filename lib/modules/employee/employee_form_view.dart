import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../widgets/app_colors.dart';
import 'employee_form_controller.dart';

class EmployeeFormView extends GetView<EmployeeFormController> {
  const EmployeeFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Obx(() => Text(
              controller.isEditing.value ? 'Edit Employee' : 'New Employee',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            )),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.badge_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(() => Text(
                                controller.isEditing.value ? 'Update Employee Details' : 'Add Employee Record',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              )),
                          const SizedBox(height: 4),
                          const Text(
                            'Please fill out all required fields marked below.',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name
                    _buildFieldLabel('Full Name *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: controller.nameController,
                      validator: controller.validateName,
                      textInputAction: TextInputAction.next,
                      decoration: _buildInputDecoration(
                        hintText: 'e.g. John Doe',
                        prefixIcon: Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Email Address
                    _buildFieldLabel('Email Address *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: controller.emailController,
                      validator: controller.validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _buildInputDecoration(
                        hintText: 'e.g. john.doe@company.com',
                        prefixIcon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Phone Number
                    _buildFieldLabel('Phone Number *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: controller.phoneController,
                      validator: controller.validatePhone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: _buildInputDecoration(
                        hintText: 'e.g. 012345678',
                        prefixIcon: Icons.phone_outlined,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Department (Dynamic Selection & Custom Input)
                    _buildFieldLabel('Department *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: controller.departmentController,
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Department is required' : null,
                      textInputAction: TextInputAction.next,
                      decoration: _buildInputDecoration(
                        hintText: 'e.g. Engineering, Marketing, Finance...',
                        prefixIcon: Icons.apartment_rounded,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: controller.departments.map((dept) {
                          return ActionChip(
                            label: Text(dept, style: const TextStyle(fontSize: 11)),
                            backgroundColor: const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            onPressed: () {
                              controller.departmentController.text = dept;
                              controller.selectedDepartment.value = dept;
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Position / Job Title
                    _buildFieldLabel('Job Position / Title *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: controller.positionController,
                      validator: controller.validatePosition,
                      textInputAction: TextInputAction.next,
                      decoration: _buildInputDecoration(
                        hintText: 'e.g. Senior Flutter Developer',
                        prefixIcon: Icons.work_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Monthly Salary
                    _buildFieldLabel('Monthly Salary (USD) *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: controller.salaryController,
                      validator: controller.validateSalary,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      textInputAction: TextInputAction.done,
                      decoration: _buildInputDecoration(
                        hintText: 'e.g. 2500.00',
                        prefixIcon: Icons.attach_money_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Submit Button
              Obx(() {
                final saving = controller.isSaving.value;
                return ElevatedButton(
                  onPressed: saving ? null : controller.submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              controller.isEditing.value ? Icons.save_rounded : Icons.check_circle_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              controller.isEditing.value ? 'Update Employee' : 'Create Employee',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                );
              }),
              const SizedBox(height: 12),

              // Cancel Button
              OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hintText, required IconData prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade600, width: 1.5),
      ),
    );
  }
}

