import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/language_service.dart';
import '../../../models/rental/room_model.dart';
import '../../../models/rental/facility_preset.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/room_image_widget.dart';
import '../../../routes/app_route_name.dart';
import '../floors/owner_floors_controller.dart';
import '../membership/owner_membership_view.dart';
import 'owner_rooms_controller.dart';

class OwnerRoomsView extends GetView<OwnerRoomsController> {
  final bool showAppBar;
  const OwnerRoomsView({super.key, this.showAppBar = false});

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

  void _showImageSourceSheet({
    required BuildContext context,
    required Function(ImageSource) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                LanguageService.isKhmer ? "ជ្រើសរើសប្រភពរូបថត" : "Select Photo Source",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: Text(LanguageService.isKhmer ? "ថតរូបភាពផ្ទាល់ (Camera)" : "Take a Photo (Camera)"),
                onTap: () {
                  Navigator.pop(ctx);
                  onSelect(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                ),
                title: Text(LanguageService.isKhmer ? "ជ្រើសពីវិចិត្រសាល (Gallery - ច្រើនរូប)" : "Choose from Gallery (Multiple)"),
                subtitle: Text(
                  LanguageService.isKhmer ? "អាចជ្រើសរើសរូបថតបានច្រើនសន្លឹកក្នុងពេលតែមួយ" : "You can select multiple photos at once",
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onSelect(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddRoomDialog(BuildContext context) {
    _showRoomDialog(context);
  }

  void _showRoomDialog(BuildContext context, {RoomModel? roomToEdit}) {
    final isEdit = roomToEdit != null;
    final List<String> pickedImages = List<String>.from(roomToEdit?.imageList ?? []);
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
                  // 0. Room Photo Uploader (Multi-Photo)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        LanguageService.isKhmer
                            ? "រូបថតបន្ទប់ (${pickedImages.length})"
                            : "Room Photos (${pickedImages.length})",
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      if (pickedImages.isNotEmpty)
                        InkWell(
                          onTap: () {
                            _showImageSourceSheet(
                              context: ctx,
                              onSelect: (source) async {
                                try {
                                  final picker = ImagePicker();
                                  if (source == ImageSource.gallery) {
                                    final pickedList = await picker.pickMultiImage(
                                      maxWidth: 1024,
                                      maxHeight: 1024,
                                      imageQuality: 85,
                                    );
                                    if (pickedList.isNotEmpty) {
                                      for (var xFile in pickedList) {
                                        final bytes = await xFile.readAsBytes();
                                        final base64String = "data:image/jpeg;base64,${base64Encode(bytes)}";
                                        pickedImages.add(base64String);
                                      }
                                      setState(() {});
                                    }
                                  } else {
                                    final img = await picker.pickImage(
                                      source: ImageSource.camera,
                                      maxWidth: 1024,
                                      maxHeight: 1024,
                                      imageQuality: 85,
                                    );
                                    if (img != null) {
                                      final bytes = await img.readAsBytes();
                                      final base64String = "data:image/jpeg;base64,${base64Encode(bytes)}";
                                      pickedImages.add(base64String);
                                      setState(() {});
                                    }
                                  }
                                } catch (e) {
                                  Get.snackbar('error'.tr, e.toString(), backgroundColor: Colors.red.shade50);
                                }
                              },
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.add_photo_alternate_outlined, size: 16, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  LanguageService.isKhmer ? "បន្ថែមរូបថត" : "Add Photos",
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (pickedImages.isEmpty)
                    InkWell(
                      onTap: () {
                        _showImageSourceSheet(
                          context: ctx,
                          onSelect: (source) async {
                            try {
                              final picker = ImagePicker();
                              if (source == ImageSource.gallery) {
                                final pickedList = await picker.pickMultiImage(
                                  maxWidth: 1024,
                                  maxHeight: 1024,
                                  imageQuality: 85,
                                );
                                if (pickedList.isNotEmpty) {
                                  for (var xFile in pickedList) {
                                    final bytes = await xFile.readAsBytes();
                                    final base64String = "data:image/jpeg;base64,${base64Encode(bytes)}";
                                    pickedImages.add(base64String);
                                  }
                                  setState(() {});
                                }
                              } else {
                                final img = await picker.pickImage(
                                  source: ImageSource.camera,
                                  maxWidth: 1024,
                                  maxHeight: 1024,
                                  imageQuality: 85,
                                );
                                if (img != null) {
                                  final bytes = await img.readAsBytes();
                                  final base64String = "data:image/jpeg;base64,${base64Encode(bytes)}";
                                  pickedImages.add(base64String);
                                  setState(() {});
                                }
                              }
                            } catch (e) {
                              Get.snackbar('error'.tr, e.toString(), backgroundColor: Colors.red.shade50);
                            }
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        height: 125,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_outlined, size: 30, color: AppColors.primary),
                            const SizedBox(height: 6),
                            Text(
                              LanguageService.isKhmer ? "បញ្ចូលរូបថតបន្ទប់ (ជ្រើសបានច្រើនរូប)" : "Upload Room Photos (Multiple)",
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              LanguageService.isKhmer ? "ចុចដើម្បីថតរូប ឬជ្រើសពីវិចិត្រសាល" : "Tap to capture from camera or choose from gallery",
                              style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: pickedImages.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) {
                          if (i == pickedImages.length) {
                            // "Add More" card
                            return InkWell(
                              onTap: () {
                                _showImageSourceSheet(
                                  context: ctx,
                                  onSelect: (source) async {
                                    try {
                                      final picker = ImagePicker();
                                      if (source == ImageSource.gallery) {
                                        final pickedList = await picker.pickMultiImage(
                                          maxWidth: 1024,
                                          maxHeight: 1024,
                                          imageQuality: 85,
                                        );
                                        if (pickedList.isNotEmpty) {
                                          for (var xFile in pickedList) {
                                            final bytes = await xFile.readAsBytes();
                                            final base64String = "data:image/jpeg;base64,${base64Encode(bytes)}";
                                            pickedImages.add(base64String);
                                          }
                                          setState(() {});
                                        }
                                      } else {
                                        final img = await picker.pickImage(
                                          source: ImageSource.camera,
                                          maxWidth: 1024,
                                          maxHeight: 1024,
                                          imageQuality: 85,
                                        );
                                        if (img != null) {
                                          final bytes = await img.readAsBytes();
                                          final base64String = "data:image/jpeg;base64,${base64Encode(bytes)}";
                                          pickedImages.add(base64String);
                                          setState(() {});
                                        }
                                      }
                                    } catch (e) {
                                      Get.snackbar('error'.tr, e.toString(), backgroundColor: Colors.red.shade50);
                                    }
                                  },
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 80,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_circle_outline_rounded, size: 24, color: AppColors.primary),
                                    const SizedBox(height: 4),
                                    Text(
                                      LanguageService.isKhmer ? "បន្ថែម" : "Add More",
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final isCover = i == 0;
                          return Container(
                            width: 100,
                            height: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCover ? AppColors.primary : AppColors.border,
                                width: isCover ? 2 : 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  RoomImageWidget(
                                    image: pickedImages[i],
                                    fit: BoxFit.cover,
                                  ),
                                  if (isCover)
                                    Positioned(
                                      top: 5,
                                      left: 5,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          LanguageService.isKhmer ? "រូបតំណាង" : "Cover",
                                          style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 5,
                                    left: 5,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        "#${i + 1}",
                                        style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          pickedImages.removeAt(i);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(3.5),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 14),

                  // 1. Room Number
                  Text('room_number'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
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
                          if (!isEdit && !controller.canAddMoreRooms) {
                            Navigator.pop(ctx);
                            _showPlanLimitDialog(context);
                            return;
                          }
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

                          final String? finalImage = pickedImages.isEmpty
                              ? null
                              : (pickedImages.length == 1 ? pickedImages.first : jsonEncode(pickedImages));

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
                              image: finalImage,
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
                              image: finalImage,
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
              leading: const Icon(Icons.remove_red_eye_outlined, color: AppColors.primary),
              title: Text(LanguageService.isKhmer ? "មើលព័ត៌មានលម្អិត និងរូបភាពបន្ទប់" : "View Room Detail & Photos"),
              subtitle: Text(
                LanguageService.isKhmer ? "បើកមើល និងបញ្ចូល/ប្តូររូបភាពបន្ទប់" : "View detail & upload/change photos",
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Get.toNamed(AppRouteName.roomDetail, arguments: {'room': room, 'canEdit': true});
              },
            ),
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
        appBar: showAppBar
            ? CustomAppBar(
                title: 'rooms'.tr,
                showProperty: false,
                showLanguage: false,
                isOwner: true,
              )
            : null,
        body: Column(
          children: [
            // Search & Filter header
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    onChanged: (v) {
                      controller.searchQuery.value = v;
                      controller.resetPagination();
                    },
                    decoration: InputDecoration(
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
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildChip("ALL", 'all'.tr),
                              const SizedBox(width: 8),
                              _buildChip("AVAILABLE", 'available'.tr),
                              const SizedBox(width: 8),
                              _buildChip("OCCUPIED", 'occupied'.tr),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildPlanUsageBadge(context),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Room List
            Expanded(
              child: Obx(() {
                final allRooms = controller.filteredRooms;
                if (allRooms.isEmpty) {
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

                final limit = controller.visibleLimit.value;
                final displayedRooms = allRooms.take(limit).toList();
                final hasMore = limit < allRooms.length;
                final loading = controller.isLoadingMore.value;
                final extraCount = (hasMore || allRooms.length > 5) ? 1 : 0;

                return NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 60) {
                      controller.loadMore();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayedRooms.length + extraCount,
                    itemBuilder: (ctx, i) {
                      if (i == displayedRooms.length) {
                        if (hasMore) {
                          return loading
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          LanguageService.isKhmer ? "កំពុងទាញយកទិន្នន័យ ៥ ទៀត..." : "Loading 5 more...",
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : InkWell(
                                  onTap: controller.loadMore,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 4, bottom: 16),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.primary),
                                        const SizedBox(width: 6),
                                        Text(
                                          LanguageService.isKhmer
                                              ? "បង្ហាញ ៥ ទៀត • នៅសល់ ${allRooms.length - displayedRooms.length}"
                                              : "Show 5 More • ${allRooms.length - displayedRooms.length} remaining",
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: Text(
                                LanguageService.isKhmer
                                    ? "បានបង្ហាញបន្ទប់ទាំងអស់ហើយ • សរុប ${allRooms.length}"
                                    : "All rooms loaded • ${allRooms.length} total",
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ),
                          );
                        }
                      }

                      final room = displayedRooms[i];
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
                              if (room.imageList.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        RoomImageWidget(
                                          image: room.imageList.first,
                                          fit: BoxFit.cover,
                                        ),
                                        if (room.imageList.length > 1)
                                          Positioned(
                                            bottom: 1.5,
                                            right: 1.5,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 0.65),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                "${room.imageList.length}",
                                                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                )
                              else
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
                                        Flexible(
                                          child: Text(
                                            room.roomNumber ?? 'room_label_prefix'.tr,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: "${'gender_spec'.tr}: ${room.genderPreferenceDisplayName}",
                                            style: const TextStyle(color: AppColors.textMuted),
                                          ),
                                          if (room.facilities != null && room.facilities!.isNotEmpty) ...[
                                            const TextSpan(text: " • ", style: TextStyle(color: AppColors.textMuted)),
                                            TextSpan(
                                              text: "${room.facilities!.length} ${'room_facilities'.tr}",
                                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ],
                                      ),
                                      style: const TextStyle(fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
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
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                padding: const EdgeInsets.all(4),
                                icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary, size: 20),
                                onPressed: () => _showRoomActionSheet(context, room),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (!controller.canAddMoreRooms) {
              _showPlanLimitDialog(context);
              return;
            }
            _showAddRoomDialog(context);
          },
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white, size: 26),
        ),
      );
    });
  }

  Widget _buildPlanUsageBadge(BuildContext context) {
    return Obx(() {
      final isOver = controller.isOverPlanLimit;
      final text = controller.roomUsageText;
      return InkWell(
        onTap: () => _showPlanLimitDialog(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: isOver
                ? AppColors.danger.withValues(alpha: 0.1)
                : AppColors.primarySoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isOver
                  ? AppColors.danger.withValues(alpha: 0.4)
                  : AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOver ? Icons.warning_amber_rounded : Icons.meeting_room_rounded,
                size: 13,
                color: isOver ? AppColors.danger : AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isOver ? AppColors.danger : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showPlanLimitDialog(BuildContext context) {
    final planName = controller.currentPlanNameDisplay;
    final maxRooms = controller.maxAllowedRooms;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 26),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                LanguageService.isKhmer ? "ដល់ដែនកំណត់បន្ទប់" : "Room Limit Reached",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LanguageService.isKhmer
                  ? "គម្រោងបច្ចុប្បន្នរបស់អ្នក ($planName) អនុញ្ញាតអតិបរមាត្រឹម $maxRooms បន្ទប់ប៉ុណ្ណោះ។"
                  : "Your current plan ($planName) allows a maximum of $maxRooms rooms.",
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 10),
            Text(
              LanguageService.isKhmer
                  ? "សូមដំឡើងទៅកាន់ កញ្ចប់ស្តង់ដារ (Standard) ឬ កញ្ចប់ពិសេស (Premium) ដើម្បីអាចបង្កើត និងគ្រប់គ្រងបន្ទប់បន្ថែមបាន។"
                  : "Please upgrade to Standard (up to 20 rooms) or Premium (unlimited rooms) to create and manage more rooms.",
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              LanguageService.isKhmer ? "ពេលក្រោយ" : "Later",
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Get.to(() => const OwnerMembershipView());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              LanguageService.isKhmer ? "ដំឡើងគម្រោង" : "Upgrade Plan",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String code, String label) {
    return Obx(() {
      final isSelected = controller.selectedFilter.value == code;
      return InkWell(
        onTap: () {
          controller.selectedFilter.value = code;
          controller.resetPagination();
        },
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
