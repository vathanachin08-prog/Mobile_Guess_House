import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/language_service.dart';
import '../../../models/rental/tenant_model.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/custom_app_bar.dart';
import '../floors/owner_floors_controller.dart';
import '../rooms/owner_rooms_controller.dart';
import 'owner_tenants_controller.dart';

class _FloorOption {
  final int floorNumber;
  final String displayName;

  const _FloorOption({required this.floorNumber, required this.displayName});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _FloorOption &&
          runtimeType == other.runtimeType &&
          floorNumber == other.floorNumber;

  @override
  int get hashCode => floorNumber.hashCode;
}

class OwnerTenantsView extends StatefulWidget {
  final bool showAppBar;
  const OwnerTenantsView({super.key, this.showAppBar = false});

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

  String _formatFloorName(int fNum) {
    if (fNum == 1) {
      return LanguageService.isKhmer ? "ជាន់ផ្ទាល់ដី" : "Ground Floor";
    }
    final actualNum = fNum > 1 ? fNum - 1 : fNum;
    final khmerDigits = {'1': '១', '2': '២', '3': '៣', '4': '៤', '5': '៥', '6': '៦', '7': '៧', '8': '៨', '9': '៩', '0': '០'};
    String khmerNum = actualNum.toString();
    khmerDigits.forEach((k, v) => khmerNum = khmerNum.replaceAll(k, v));
    return LanguageService.isKhmer ? "ជាន់ទី $khmerNum" : "Floor $actualNum";
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
              onTap: () {
                Navigator.pop(ctx);
                _showAddTenantDialog(tenantToEdit: tenant);
              },
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

  void _showAddTenantDialog({TenantModel? tenantToEdit}) {
    final isEdit = tenantToEdit != null;
    final nameCtrl = TextEditingController(text: tenantToEdit?.name ?? '');
    final phoneCtrl = TextEditingController(text: tenantToEdit?.phoneNumber ?? '');
    final customRoomCtrl = TextEditingController(text: tenantToEdit?.roomNumber ?? '');

    // Get floor and room controllers
    final floorsCtrl = Get.isRegistered<OwnerFloorsController>()
        ? Get.find<OwnerFloorsController>()
        : (Get.isRegistered<ApiService>()
            ? Get.put(OwnerFloorsController(apiService: Get.find<ApiService>()))
            : null);
    final roomsCtrl = Get.isRegistered<OwnerRoomsController>()
        ? Get.find<OwnerRoomsController>()
        : (Get.isRegistered<ApiService>()
            ? Get.put(OwnerRoomsController(apiService: Get.find<ApiService>()))
            : Get.put(OwnerRoomsController()));

    // Collect available floors
    final floorOptions = <_FloorOption>[];
    final seenFloors = <int>{};

    if (floorsCtrl != null) {
      for (var f in floorsCtrl.floors) {
        final fNum = f.floorNumber;
        if (!seenFloors.contains(fNum)) {
          seenFloors.add(fNum);
          floorOptions.add(_FloorOption(
            floorNumber: fNum,
            displayName: f.name.isNotEmpty ? f.name : _formatFloorName(fNum),
          ));
        }
      }
    }

    for (var r in roomsCtrl.rooms) {
      if (r.floor != null && !seenFloors.contains(r.floor!)) {
        seenFloors.add(r.floor!);
        floorOptions.add(_FloorOption(
          floorNumber: r.floor!,
          displayName: r.floorDisplayName,
        ));
      }
    }

    if (floorOptions.isEmpty) {
      floorOptions.add(_FloorOption(
        floorNumber: 1,
        displayName: LanguageService.isKhmer ? "ជាន់ផ្ទាល់ដី" : "Ground Floor",
      ));
      floorOptions.add(_FloorOption(
        floorNumber: 2,
        displayName: LanguageService.isKhmer ? "ជាន់ទី ១" : "Floor 1",
      ));
      floorOptions.add(_FloorOption(
        floorNumber: 3,
        displayName: LanguageService.isKhmer ? "ជាន់ទី ២" : "Floor 2",
      ));
    }

    floorOptions.sort((a, b) => a.floorNumber.compareTo(b.floorNumber));

    // Initial floor
    int selectedFloorNumber = floorOptions.first.floorNumber;
    if (tenantToEdit?.floor != null) {
      final match = floorOptions.firstWhereOrNull((f) =>
          f.displayName.toLowerCase() == tenantToEdit!.floor!.toLowerCase() ||
          tenantToEdit.floor!.contains(f.floorNumber.toString()));
      if (match != null) {
        selectedFloorNumber = match.floorNumber;
      }
    }

    String? selectedRoomNumber = tenantToEdit?.roomNumber;
    bool isCustomRoom = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Filter rooms belonging to the selected floor
          final roomsOnSelectedFloor = roomsCtrl.rooms
              .where((r) => r.floor == selectedFloorNumber)
              .toList();

          // Auto-select valid room for current floor if available
          if (!isCustomRoom && roomsOnSelectedFloor.isNotEmpty) {
            final isValid = roomsOnSelectedFloor.any((r) => r.roomNumber == selectedRoomNumber);
            if (!isValid) {
              selectedRoomNumber = roomsOnSelectedFloor.first.roomNumber;
            }
          }

          final selectedFloorObj = floorOptions.firstWhere(
            (f) => f.floorNumber == selectedFloorNumber,
            orElse: () => floorOptions.first,
          );

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_add_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isEdit
                        ? (LanguageService.isKhmer ? 'កែសម្រួលអ្នកជួល' : 'Edit Tenant')
                        : 'add_tenant'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'full_name'.tr,
                        hintText: LanguageService.isKhmer ? "ឧ. ចាន់ តារា" : "e.g. John Doe",
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Phone Number
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'phone'.tr,
                        hintText: "012 345 678",
                        prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Floor Selector Dropdown
                    DropdownButtonFormField<int>(
                      value: selectedFloorNumber,
                      decoration: InputDecoration(
                        labelText: 'floor_number'.tr,
                        prefixIcon: const Icon(Icons.layers_outlined, color: AppColors.primary, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: floorOptions.map((f) {
                        return DropdownMenuItem<int>(
                          value: f.floorNumber,
                          child: Text(
                            f.displayName,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedFloorNumber = val;
                            selectedRoomNumber = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Dynamic Room Selector / Manual Room Input based on selected floor
                    if (roomsOnSelectedFloor.isNotEmpty && !isCustomRoom) ...[
                      DropdownButtonFormField<String>(
                        value: selectedRoomNumber,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'room_number'.tr,
                          prefixIcon: const Icon(Icons.meeting_room_outlined, color: AppColors.primary, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        items: roomsOnSelectedFloor.map((r) {
                          final rNum = r.roomNumber ?? 'Room';
                          final isAvail = r.available ?? true;
                          final statusLabel = isAvail
                              ? (LanguageService.isKhmer ? "ទំនេរ" : "Available")
                              : (LanguageService.isKhmer ? "មានអ្នកជួល" : "Occupied");

                          return DropdownMenuItem<String>(
                            value: rNum,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${'room'.tr} $rNum",
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isAvail ? AppColors.primarySoft : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isAvail ? AppColors.primary : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedRoomNumber = val;
                          });
                        },
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () {
                            setDialogState(() {
                              isCustomRoom = true;
                              customRoomCtrl.text = selectedRoomNumber ?? '';
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                            child: Text(
                              LanguageService.isKhmer ? "បញ្ចូលលេខបន្ទប់ដោយផ្ទាល់" : "Enter room number manually",
                              style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      if (roomsOnSelectedFloor.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.amber.shade800),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  LanguageService.isKhmer
                                      ? "មិនមានបន្ទប់នៅលើជាន់នេះនៅឡើយទេ សូមបញ្ចូលលេខបន្ទប់ដោយផ្ទាល់"
                                      : "No registered rooms on this floor yet. Enter room number below:",
                                  style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                                ),
                              ),
                            ],
                          ),
                        ),
                      TextField(
                        controller: customRoomCtrl,
                        decoration: InputDecoration(
                          labelText: 'room_number'.tr,
                          hintText: LanguageService.isKhmer ? "ឧ. 101 ឬ 00003" : "e.g. 101 or 00003",
                          prefixIcon: const Icon(Icons.meeting_room_outlined, color: AppColors.primary, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      if (roomsOnSelectedFloor.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () {
                              setDialogState(() {
                                isCustomRoom = false;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                              child: Text(
                                LanguageService.isKhmer ? "ជ្រើសរើសពីបញ្ជីបន្ទប់" : "Select from room list",
                                style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('cancel'.tr, style: const TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () {
                  final tenantName = nameCtrl.text.trim();
                  final phone = phoneCtrl.text.trim();
                  final roomNumber = isCustomRoom
                      ? customRoomCtrl.text.trim()
                      : (selectedRoomNumber ?? customRoomCtrl.text.trim());
                  final floorDisplayName = selectedFloorObj.displayName;

                  if (tenantName.isEmpty) {
                    Get.snackbar(
                      'error'.tr,
                      LanguageService.isKhmer ? 'សូមបញ្ចូលឈ្មោះអ្នកជួល' : 'Please enter tenant name',
                      backgroundColor: Colors.red.shade50,
                      margin: const EdgeInsets.all(16),
                    );
                    return;
                  }

                  if (roomNumber.isEmpty) {
                    Get.snackbar(
                      'error'.tr,
                      LanguageService.isKhmer ? 'សូមជ្រើសរើស ឬបញ្ចូលលេខបន្ទប់' : 'Please select or enter room number',
                      backgroundColor: Colors.red.shade50,
                      margin: const EdgeInsets.all(16),
                    );
                    return;
                  }

                  AppFirebaseService.logAddTenantForm(
                    tenantName: tenantName,
                    roomNumber: roomNumber,
                    success: true,
                  );

                  if (isEdit) {
                    controller.updateTenant(
                      id: tenantToEdit.id!,
                      name: tenantName,
                      roomNumber: roomNumber,
                      floor: floorDisplayName,
                      phone: phone.isNotEmpty ? phone : "012345678",
                    );
                  } else {
                    controller.addTenant(
                      name: tenantName,
                      roomNumber: roomNumber,
                      floor: floorDisplayName,
                      phone: phone.isNotEmpty ? phone : "012345678",
                    );
                  }

                  // Auto mark room as occupied if it was available
                  final matching = roomsCtrl.rooms.firstWhereOrNull((r) => r.roomNumber == roomNumber);
                  if (matching != null && (matching.available ?? true)) {
                    roomsCtrl.toggleAvailability(matching);
                  }

                  Navigator.pop(ctx);
                  Get.snackbar(
                    'success'.tr,
                    "$tenantName - ${'room'.tr} $roomNumber ($floorDisplayName)",
                    backgroundColor: Colors.green.shade50,
                    margin: const EdgeInsets.all(16),
                    icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('confirm'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
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
                title: 'tenants'.tr,
                showProperty: false,
                showLanguage: false,
                isOwner: true,
              )
            : null,
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
