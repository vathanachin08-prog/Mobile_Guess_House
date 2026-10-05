import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/language_service.dart';
import '../../../models/rental/tenant_model.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/custom_app_bar.dart';
import 'owner_tenants_controller.dart';

class OwnerTenantsView extends StatefulWidget {
  const OwnerTenantsView({super.key});

  @override
  State<OwnerTenantsView> createState() => _OwnerTenantsViewState();
}

class _OwnerTenantsViewState extends State<OwnerTenantsView> {
  final searchController = TextEditingController();
  late final OwnerTenantsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<OwnerTenantsController>()
        ? Get.find<OwnerTenantsController>()
        : Get.put(OwnerTenantsController());
    searchController.addListener(() {
      controller.searchQuery.value = searchController.text;
    });
  }

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
            Text('actions'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined, color: AppColors.accentOrange),
              title: Text('remove_from_room'.tr),
              onTap: () {
                controller.removeTenant(tenant.id);
                Navigator.pop(ctx);
                Get.snackbar(
                  'notice'.tr,
                  "${tenant.name} - ${tenant.roomNumber}",
                  backgroundColor: Colors.white,
                  margin: const EdgeInsets.all(16),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
              title: Text('manage_invoice'.tr),
              onTap: () {
                Navigator.pop(ctx);
                Get.snackbar('notice'.tr, "${tenant.name}");
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.accentBlue),
              title: Text('edit'.tr),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              title: Text('delete'.tr, style: const TextStyle(color: AppColors.danger)),
              onTap: () {
                controller.removeTenant(tenant.id);
                Navigator.pop(ctx);
                Get.snackbar('delete'.tr, "${tenant.name}", backgroundColor: Colors.white, margin: const EdgeInsets.all(16));
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
    final floorCtrl = TextEditingController(text: "Floor 2");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('add_tenant'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: 'full_name'.tr),
              ),
              TextField(
                controller: phoneCtrl,
                decoration: InputDecoration(labelText: 'phone'.tr),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: roomCtrl,
                decoration: InputDecoration(labelText: 'room_number'.tr),
              ),
              TextField(
                controller: floorCtrl,
                decoration: InputDecoration(labelText: 'floor_number'.tr),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () {
              final tenantName = nameCtrl.text.trim();
              final roomNumber = roomCtrl.text.trim();
              final phone = phoneCtrl.text.trim();
              final floor = floorCtrl.text.trim();
              if (tenantName.isNotEmpty) {
                AppFirebaseService.logAddTenantForm(
                  tenantName: tenantName,
                  roomNumber: roomNumber,
                  success: true,
                );
                controller.addTenant(
                  name: tenantName,
                  roomNumber: roomNumber.isNotEmpty ? roomNumber : "00001",
                  floor: floor.isNotEmpty ? floor : "Floor 1",
                  phone: phone.isNotEmpty ? phone : "012345678",
                );
                Navigator.pop(ctx);
                Get.snackbar(
                  'success'.tr,
                  tenantName,
                  backgroundColor: Colors.green.shade50,
                  margin: const EdgeInsets.all(16),
                );
              } else {
                AppFirebaseService.logAddTenantForm(
                  tenantName: '',
                  roomNumber: roomNumber,
                  success: false,
                );
                Get.snackbar('error'.tr, 'full_name'.tr);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      LanguageService.currentLocale.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: 'tenants'.tr,
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
                      hintText: "${'search'.tr}...",
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('all'.tr, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                        const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Tenants List (Photo 6)
            Expanded(
              child: Obx(() {
                final list = controller.filteredTenants;
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'no_data'.tr,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final t = list[i];
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
                                  (t.name != null && t.name!.isNotEmpty) ? t.name!.substring(0, 1) : "T",
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
                );
              }),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddTenantDialog,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white, size: 26),
        ),
      );
    });
  }
}
