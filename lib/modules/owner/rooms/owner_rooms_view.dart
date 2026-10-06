import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/language_service.dart';
import '../../../models/rental/room_model.dart';
import '../../../models/rental/facility_preset.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/custom_app_bar.dart';
import '../floors/owner_floors_controller.dart';
import 'owner_rooms_controller.dart';

class OwnerRoomsView extends GetView<OwnerRoomsController> {
  const OwnerRoomsView({super.key});

  String _getFloorDisplayName(int? floorNum) {
    if (Get.isRegistered<OwnerFloorsController>()) {
      final floors = Get.find<OwnerFloorsController>().floors;
      final match = floors.firstWhereOrNull((f) => f.floorNumber == floorNum);
      if (match != null && match.name.isNotEmpty) {
        return match.name;
      }
    }
    if (floorNum == null || floorNum == 0 || floorNum == 1) {
      return LanguageService.isKhmer ? "ជាន់ផ្ទាល់ដី" : "Ground Floor";
    }
    final actualNum = floorNum > 1 ? floorNum - 1 : floorNum;
    final khmerDigits = {'1': '១', '2': '២', '3': '៣', '4': '៤', '5': '៥', '6': '៦', '7': '៧', '8': '៨', '9': '៩', '0': '០'};
    String khmerNum = actualNum.toString();
    khmerDigits.forEach((k, v) => khmerNum = khmerNum.replaceAll(k, v));
    return LanguageService.isKhmer ? "ជាន់ទី $khmerNum" : "Floor $actualNum";
  }

  void _showAddRoomDialog(BuildContext context) {
    _showRoomDialog(context);
  }

  void _showRoomDialog(BuildContext context, {RoomModel? roomToEdit}) {
    final isEdit = roomToEdit != null;
    final nameCtrl = TextEditingController(text: roomToEdit?.roomNumber ?? '');
    final priceCtrl = TextEditingController(
      text: roomToEdit?.price != null ? roomToEdit!.price!.toStringAsFixed(0) : "50",
    );
    final areaCtrl = TextEditingController(
      text: roomToEdit?.area != null
          ? roomToEdit!.area!.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')
          : "18",
    );
    final descCtrl = TextEditingController(text: roomToEdit?.description ?? '');

    String selectedRoomType = (roomToEdit?.roomType != null &&
            ['SINGLE', 'DOUBLE', 'SHARED'].contains(roomToEdit!.roomType!.toUpperCase()))
        ? roomToEdit.roomType!.toUpperCase()
        : 'SINGLE';

    String selectedGender = (roomToEdit?.genderPreference != null &&
            ['ANY', 'MALE', 'FEMALE'].contains(roomToEdit!.genderPreference!.toUpperCase()))
        ? roomToEdit.genderPreference!.toUpperCase()
        : 'ANY';

    Set<int> selectedFacilities = {};
    if (isEdit && roomToEdit.facilities != null && roomToEdit.facilities!.isNotEmpty) {
      for (var f in roomToEdit.facilities!) {
        if (f.id != null && f.id! > 0) {
          selectedFacilities.add(f.id!);
        } else if (f.name != null) {
          final match = kAllFacilityPresets.firstWhereOrNull((p) =>
              p.code.toUpperCase() == f.name!.toUpperCase() ||
              f.name!.toUpperCase().contains(p.code.toUpperCase()));
          if (match != null) selectedFacilities.add(match.id);
        }
      }
    }
    if (selectedFacilities.isEmpty) {
      selectedFacilities = {1, 2, 3}; // WIFI, AIR_CONDITIONER, PRIVATE_BATHROOM by default
    }

    // Dynamically retrieve list of available floors from OwnerFloorsController
    final floorsCtrl = Get.isRegistered<OwnerFloorsController>()
        ? Get.find<OwnerFloorsController>()
        : (Get.isRegistered<ApiService>()
            ? Get.put(OwnerFloorsController(apiService: Get.find<ApiService>()))
            : null);
    final availableFloors = floorsCtrl?.floors.toList() ?? [];

    List<DropdownMenuItem<int>> floorDropdownItems = [];
    final seen = <int>{};
    for (var f in availableFloors) {
      final fNum = f.floorNumber;
      if (!seen.contains(fNum)) {
        seen.add(fNum);
        floorDropdownItems.add(DropdownMenuItem(
          value: fNum,
          child: Text(f.name.isNotEmpty ? f.name : (LanguageService.isKhmer ? "ជាន់ទី $fNum" : "Floor $fNum")),
        ));
      }
    }

    if (roomToEdit?.floor != null && !seen.contains(roomToEdit!.floor!)) {
      final fNum = roomToEdit.floor!;
      floorDropdownItems.insert(
        0,
        DropdownMenuItem(
          value: fNum,
          child: Text(_getFloorDisplayName(fNum)),
        ),
      );
      seen.add(fNum);
    }

    bool isCreatingNewFloor = !isEdit && availableFloors.isEmpty;
    final floorNameCtrl = TextEditingController(
      text: availableFloors.isEmpty ? (LanguageService.isKhmer ? "ជាន់ទី ១" : "Floor 1") : "",
    );
    int? selectedFloor = roomToEdit?.floor ?? (availableFloors.isNotEmpty ? availableFloors.first.floorNumber : 1);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'edit_room'.tr : 'create_room'.tr,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEdit ? 'edit_room_desc'.tr : 'create_room_desc'.tr,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Room Number
                  Text('room_number'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: LanguageService.isKhmer ? "ខ. បន្ទប់ ១០១ ឬ 00006" : "e.g. Room 101 or 00006",
                      hintStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Floor Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('floor_number'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      if (availableFloors.isNotEmpty && !isEdit)
                        InkWell(
                          onTap: () {
                            setState(() {
                              isCreatingNewFloor = !isCreatingNewFloor;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                            child: Text(
                              isCreatingNewFloor ? 'select_from_floor_list'.tr : 'add_new_floor_option'.tr,
                              style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      else if (!isEdit)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Text(
                            'first_floor_badge'.tr,
                            style: const TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (!isCreatingNewFloor) ...[
                    DropdownButtonFormField<int>(
                      initialValue: selectedFloor,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.layers_outlined, size: 20, color: AppColors.primary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: floorDropdownItems,
                      onChanged: (val) => setState(() => selectedFloor = val),
                    ),
                  ] else ...[
                    TextField(
                      controller: floorNameCtrl,
                      decoration: InputDecoration(
                        hintText: LanguageService.isKhmer
                            ? (availableFloors.isEmpty ? "ឧ. ជាន់ទី ១ ឬ ជាន់ផ្ទាល់ដី" : "ឧ. ជាន់ទី ${availableFloors.length + 1}")
                            : (availableFloors.isEmpty ? "e.g. Floor 1 or Ground Floor" : "e.g. Floor ${availableFloors.length + 1}"),
                        hintStyle: const TextStyle(fontSize: 12),
                        prefixIcon: const Icon(Icons.layers_outlined, size: 20, color: AppColors.primary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      availableFloors.isEmpty ? 'auto_create_floor_info'.tr : 'auto_new_floor_info'.tr,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // 3. Price & Area (Row)
                  Row(
                    children: [
                      // Rent Price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('rent_price_label'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "50",
                                prefixText: "\$ ",
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Room Area (m²)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('room_size_m2'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: areaCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: "18",
                                suffixText: "m²",
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 4. Room Type & Gender Preference (Row)
                  Row(
                    children: [
                      // Room Type
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('room_type_select'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: selectedRoomType,
                              isExpanded: true,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.king_bed_outlined, size: 20, color: AppColors.primary),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              items: [
                                DropdownMenuItem(value: 'SINGLE', child: Text('single_room_opt'.tr, style: const TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'DOUBLE', child: Text('double_room_opt'.tr, style: const TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'SHARED', child: Text('shared_room_opt'.tr, style: const TextStyle(fontSize: 12))),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => selectedRoomType = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Gender Preference
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('gender_preference_select'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: selectedGender,
                              isExpanded: true,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.people_outline, size: 20, color: AppColors.primary),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              items: [
                                DropdownMenuItem(value: 'ANY', child: Text('gender_any'.tr, style: const TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'MALE', child: Text('gender_male'.tr, style: const TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'FEMALE', child: Text('gender_female'.tr, style: const TextStyle(fontSize: 12))),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => selectedGender = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 5. Room Amenities / Facilities (Multi-Select Chips)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('select_room_amenities'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      Text(
                        "${selectedFacilities.length} ${LanguageService.isKhmer ? 'បានជ្រើស' : 'selected'}",
                        style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    LanguageService.isKhmer
                        ? "ចុចលើសម្ភារៈដើម្បីជ្រើសរើស ឬដោះចេញ"
                        : "Tap amenity chips to toggle inclusion in room",
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kAllFacilityPresets.map((preset) {
                      final isSelected = selectedFacilities.contains(preset.id);
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedFacilities.remove(preset.id);
                            } else {
                              selectedFacilities.add(preset.id);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primarySoft : AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                preset.icon,
                                size: 16,
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                preset.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.check, size: 14, color: AppColors.primary),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 6. Description (Optional)
                  Text('description_optional'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'description_hint'.tr,
                      hintStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 7. Save / Update Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final number = nameCtrl.text.trim();
                        final price = double.tryParse(priceCtrl.text.trim()) ?? 50.0;
                        final area = double.tryParse(areaCtrl.text.trim()) ?? 18.0;

                        if (number.isNotEmpty) {
                          int floorToAssign = 1;
                          if (isCreatingNewFloor) {
                            final enteredName = floorNameCtrl.text.trim().isNotEmpty
                                ? floorNameCtrl.text.trim()
                                : (LanguageService.isKhmer ? "ជាន់ទី ១" : "Floor 1");
                            floorsCtrl?.addFloor(enteredName);

                            final khmerDigits = {'១': '1', '២': '2', '៣': '3', '៤': '4', '៥': '5', '៦': '6', '៧': '7', '៨': '8', '៩': '9', '០': '0'};
                            String s = enteredName;
                            khmerDigits.forEach((k, v) => s = s.replaceAll(k, v));
                            final match = RegExp(r'\d+').firstMatch(s);
                            floorToAssign = match != null ? (int.tryParse(match.group(0) ?? '') ?? 1) : 1;
                          } else {
                            floorToAssign = selectedFloor ?? 1;
                          }

                          if (isEdit) {
                            controller.updateRoom(
                              room: roomToEdit,
                              number: number,
                              floor: floorToAssign,
                              price: price,
                              area: area,
                              roomType: selectedRoomType,
                              genderPreference: selectedGender,
                              facilityIds: selectedFacilities.toList(),
                              desc: descCtrl.text.trim(),
                            );
                          } else {
                            controller.addRoom(
                              number: number,
                              floor: floorToAssign,
                              price: price,
                              area: area,
                              roomType: selectedRoomType,
                              genderPreference: selectedGender,
                              facilityIds: selectedFacilities.toList(),
                              desc: descCtrl.text.trim(),
                            );
                          }
                          Navigator.pop(ctx);
                        } else {
                          AppFirebaseService.logAddRoomForm(
                            roomNumber: '',
                            floor: selectedFloor ?? 1,
                            price: price,
                            success: false,
                            errorMessage: "Validation: Empty room number",
                          );
                          Get.snackbar('error'.tr, 'please_enter_room_num'.tr);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text('save'.tr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('cancel'.tr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showRoomActionSheet(BuildContext context, RoomModel room) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("${'room_label_prefix'.tr} ${room.roomNumber ?? ''}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
              title: Text('edit_room'.tr),
              subtitle: Text(
                LanguageService.isKhmer ? "កំណត់ទំហំ ប្រភេទ ភេទ និងឧបករណ៍ប្រើប្រាស់" : "Configure size, type, gender, facilities",
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showRoomDialog(context, roomToEdit: room);
              },
            ),
            ListTile(
              leading: Icon(
                room.available == true ? Icons.check_circle_outline : Icons.remove_circle_outline,
                color: AppColors.primary,
              ),
              title: Text(room.available == true ? 'mark_occupied'.tr : 'mark_available'.tr),
              onTap: () {
                Navigator.pop(ctx);
                controller.toggleAvailability(room);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              title: Text('delete_room'.tr, style: const TextStyle(color: AppColors.danger)),
              onTap: () {
                Navigator.pop(ctx);
                Get.defaultDialog(
                  title: 'delete_room'.tr,
                  middleText: 'delete_room_confirm'.tr,
                  textConfirm: 'delete'.tr,
                  textCancel: 'cancel'.tr,
                  confirmTextColor: Colors.white,
                  buttonColor: AppColors.danger,
                  onConfirm: () {
                    Get.back();
                    controller.deleteRoom(room);
                  },
                );
              },
            ),
          ],
        ),
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
        appBar: CustomAppBar(
          title: 'rooms'.tr,
          propertyDropdownText: "My Home",
        ),
        body: Column(
          children: [
            // Search & Filter header
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    onChanged: (v) => controller.searchQuery.value = v,
                    decoration: InputDecoration(
                      hintText: 'search_rooms_hint'.tr,
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildChip("ALL", 'all'.tr),
                      const SizedBox(width: 8),
                      _buildChip("AVAILABLE", 'available'.tr),
                      const SizedBox(width: 8),
                      _buildChip("OCCUPIED", 'occupied'.tr),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Room List
            Expanded(
              child: Obx(() {
                final list = controller.filteredRooms;
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.meeting_room_outlined, size: 56, color: AppColors.textMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 14),
                          Text(
                            'no_rooms_yet'.tr,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'no_rooms_yet_hint'.tr,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                    final room = list[i];
                    final isAvail = room.available ?? true;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showRoomDialog(context, roomToEdit: room),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isAvail ? AppColors.primarySoft : Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.meeting_room_outlined,
                                  color: isAvail ? AppColors.primary : Colors.amber.shade800,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          room.roomNumber ?? 'room_label_prefix'.tr,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.background,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: AppColors.border),
                                          ),
                                          child: Text(
                                            room.roomTypeDisplayName,
                                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      "${_getFloorDisplayName(room.floor)} • ${(room.area ?? 18).toStringAsFixed(0)} m² • \$${room.price?.toStringAsFixed(0) ?? 50}/mo",
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Text(
                                          "${'gender_spec'.tr}: ${room.genderPreferenceDisplayName}",
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        ),
                                        if (room.facilities != null && room.facilities!.isNotEmpty) ...[
                                          const Text(" • ", style: TextStyle(color: AppColors.textMuted)),
                                          Text(
                                            "${room.facilities!.length} ${'room_facilities'.tr}",
                                            style: const TextStyle(fontSize: 11, color: AppColors.primary),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isAvail ? AppColors.primarySoft : Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isAvail ? 'available'.tr : 'occupied'.tr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isAvail ? AppColors.primary : Colors.amber.shade800,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary, size: 20),
                                onPressed: () => _showRoomActionSheet(context, room),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddRoomDialog(context),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white, size: 26),
        ),
      );
    });
  }

  Widget _buildChip(String code, String label) {
    return Obx(() {
      final isSelected = controller.selectedFilter.value == code;
      return InkWell(
        onTap: () => controller.selectedFilter.value = code,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      );
    });
  }
}
