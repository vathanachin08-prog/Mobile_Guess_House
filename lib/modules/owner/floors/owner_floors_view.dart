import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/language_service.dart';
import '../../../widgets/app_clean_dialog.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/custom_app_bar.dart';
import 'owner_floors_controller.dart';

class OwnerFloorsView extends StatefulWidget {
  final bool showAppBar;
  const OwnerFloorsView({super.key, this.showAppBar = false});

  @override
  State<OwnerFloorsView> createState() => _OwnerFloorsViewState();
}

class _OwnerFloorsViewState extends State<OwnerFloorsView> {
  late final OwnerFloorsController controller;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<OwnerFloorsController>()
        ? Get.find<OwnerFloorsController>()
        : Get.put(OwnerFloorsController(apiService: Get.find<ApiService>()));
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _addFloorDialog() {
    final floorNameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AppCleanDialog(
        title: 'add_new_floor'.tr,
        subtitle: 'enter_floor_name'.tr,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: floorNameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'floor_name'.tr,
                hintText: LanguageService.isKhmer ? 'ឧ. ជាន់ទី១, ជាន់ផ្ទាល់ដី' : 'e.g. Floor 1, Ground Floor',
                prefixIcon: const Icon(Icons.layers_outlined, color: AppColors.primary, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),
          ],
        ),
        confirmText: 'add_floor'.tr,
        cancelText: 'cancel'.tr,
        onConfirm: () {
          final text = floorNameCtrl.text.trim();
          if (text.isNotEmpty) {
            AppFirebaseService.logAddFloorForm(
              floorName: text,
              success: true,
            );
            controller.addFloor(text);
            Navigator.pop(ctx);
            Get.snackbar(
              'success'.tr,
              "$text: ${'floor_created_success'.tr}",
              backgroundColor: AppColors.primary,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
              margin: const EdgeInsets.all(16),
            );
          } else {
            AppFirebaseService.logAddFloorForm(
              floorName: '',
              success: false,
              errorMessage: "Validation: Empty floor name",
            );
            Get.snackbar('error'.tr, 'please_enter_floor_name'.tr);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      LanguageService.currentLocale.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: widget.showAppBar
            ? CustomAppBar(
                title: 'floors'.tr,
                showProperty: false,
                showLanguage: false,
                isOwner: true,
              )
            : null,
        body: Column(
          children: [
            // Search input
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: searchController,
                onChanged: (val) => controller.searchQuery.value = val.trim(),
                decoration: InputDecoration(
                  hintText: LanguageService.isKhmer ? "ស្វែងរកជាន់..." : "Search floor...",
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Floors List
            Expanded(
              child: Obx(() {
                final list = controller.filteredFloors;
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      'no_data'.tr,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final floor = list[i];
                    return Container(
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
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.layers_outlined, color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  floor.name,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${controller.getRoomCountForFloor(floor)} ${'total_rooms'.tr}",
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Builder(builder: (context) {
                            final occupied = controller.getOccupiedCountForFloor(floor);
                            if (occupied <= 0) return const SizedBox.shrink();
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "$occupied ${'occupied'.tr}",
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            );
                          }),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary, size: 20),
                            onSelected: (val) {
                              if (val == 'delete') {
                                AppCleanDialog.showConfirmation(
                                  context: context,
                                  title: LanguageService.isKhmer ? "លុបជាន់" : "Delete Floor",
                                  message: LanguageService.isKhmer
                                      ? "តើអ្នកប្រាកដជាចង់លុប '${floor.name}' នេះមែនទេ? បន្ទប់ទាំងអស់ក្នុងជាន់នេះនឹងត្រូវលុបផងដែរ។"
                                      : "Are you sure you want to delete '${floor.name}'? All rooms on this floor will also be affected.",
                                  confirmText: 'delete'.tr,
                                  confirmColor: AppColors.danger,
                                  onConfirm: () {
                                    controller.deleteFloor(i);
                                    Get.snackbar(
                                      'delete'.tr,
                                      floor.name,
                                      backgroundColor: AppColors.surface,
                                      colorText: AppColors.textPrimary,
                                      snackPosition: SnackPosition.BOTTOM,
                                      margin: const EdgeInsets.all(16),
                                    );
                                  },
                                );
                              }
                            },
                            itemBuilder: (ctx) => [
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                                    const SizedBox(width: 8),
                                    Text('delete'.tr, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                                  ],
                                ),
                              ),
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
          onPressed: _addFloorDialog,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white, size: 26),
        ),
      );
    });
  }
}
