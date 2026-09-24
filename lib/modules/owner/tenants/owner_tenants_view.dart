import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/firebase_service.dart';
import '../../../models/rental/tenant_model.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/custom_app_bar.dart';

class OwnerTenantsView extends StatefulWidget {
  const OwnerTenantsView({super.key});

  @override
  State<OwnerTenantsView> createState() => _OwnerTenantsViewState();
}

class _OwnerTenantsViewState extends State<OwnerTenantsView> {
  final searchController = TextEditingController();
  final List<TenantModel> tenants = [
    TenantModel(
      id: 1,
      name: "តុលា សុខ",
      roomNumber: "00001",
      floor: "ជាន់ទី១",
      email: "myhome+1@gmail.com",
      phoneNumber: "03423423423",
      status: "ACTIVE",
    ),
    TenantModel(
      id: 2,
      name: "សុខ រដ្ឋា",
      roomNumber: "00002",
      floor: "ជាន់ទី១",
      email: "rothasok@gmail.com",
      phoneNumber: "012889900",
      status: "ACTIVE",
    ),
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
            const Text("សកម្មភាព (Actions)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined, color: AppColors.accentOrange),
              title: const Text("ដកចេញពីបន្ទប់ / Remove from room"),
              onTap: () {
                Navigator.pop(ctx);
                Get.snackbar("Notice", "ដកអ្នកជួល ${tenant.name} ចេញពីបន្ទប់ ${tenant.roomNumber} រួចរាល់");
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
              title: const Text("គ្រប់គ្រងវិក្កយបត្រ / Manage invoice"),
              onTap: () {
                Navigator.pop(ctx);
                Get.snackbar("Notice", "បើកវិក្កយបត្ររបស់អ្នកជួល ${tenant.name}");
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.accentBlue),
              title: const Text("កែសម្រួល / Edit"),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              title: const Text("លុប / Delete", style: TextStyle(color: AppColors.danger)),
              onTap: () {
                setState(() => tenants.removeWhere((t) => t.id == tenant.id));
                Navigator.pop(ctx);
                Get.snackbar("Deleted", "បានលុបអ្នកជួលរួចរាល់");
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTenantDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final roomCtrl = TextEditingController(text: "00003");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("បន្ថែមអ្នកជួលថ្មី / Add Tenant", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "ឈ្មោះអ្នកជួល / Tenant Name"),
            ),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: "លេខទូរស័ព្ទ / Phone Number"),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: roomCtrl,
              decoration: const InputDecoration(labelText: "លេខបន្ទប់ / Room Number"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("បោះបង់")),
          ElevatedButton(
            onPressed: () {
              final tenantName = nameCtrl.text.trim();
              final roomNumber = roomCtrl.text.trim();
              if (tenantName.isNotEmpty) {
                AppFirebaseService.logAddTenantForm(
                  tenantName: tenantName,
                  roomNumber: roomNumber,
                  success: true,
                );
                setState(() {
                  tenants.add(TenantModel(
                    id: tenants.length + 1,
                    name: tenantName,
                    phoneNumber: phoneCtrl.text.trim(),
                    roomNumber: roomNumber,
                    floor: "ជាន់ទី២",
                    email: "tenant@example.com",
                  ));
                });
                Navigator.pop(ctx);
                Get.snackbar("Success", "បានបន្ថែមអ្នកជួលជោគជ័យ! Tenant added.", backgroundColor: Colors.green.shade50);
              } else {
                AppFirebaseService.logAddTenantForm(
                  tenantName: '',
                  roomNumber: roomNumber,
                  success: false,
                );
                Get.snackbar("Error", "សូមបញ្ចូលឈ្មោះអ្នកជួល / Please enter tenant name");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text("បន្ថែម"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: "អ្នកជួល",
        propertyDropdownText: "My Home",
      ),
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
                    hintText: "ស្វែងរកអ្នកជួល...",
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
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
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("គ្រប់ជាន់ទី (All Floors)", style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                      Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Tenants List (Photo 6)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tenants.length,
              itemBuilder: (ctx, i) {
                final t = tenants[i];
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
                              t.name?.substring(0, 1) ?? "T",
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTenantDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
    );
  }
}
