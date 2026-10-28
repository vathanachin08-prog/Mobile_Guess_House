import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../constants/constant_uri.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/language_service.dart';
import '../../../data/local/token_store_local.dart';
import '../../../models/rental/room_model.dart';
import '../../../routes/app_route_name.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/facility_chip.dart';
import '../../../widgets/room_image_widget.dart';
import '../../owner/rooms/owner_rooms_controller.dart';
import '../property_detail/property_detail_controller.dart';
import '../visit_requests/request_visit_dialog.dart';

class RoomDetailView extends StatefulWidget {
  const RoomDetailView({super.key});

  @override
  State<RoomDetailView> createState() => _RoomDetailViewState();
}

class _RoomDetailViewState extends State<RoomDetailView> {
  late RoomModel room;
  bool _isUploading = false;
  final _storage = GetStorage();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initRoom();
  }

  void _initRoom() {
    final args = Get.arguments;
    if (args is RoomModel) {
      room = args;
      _storage.write("LAST_VIEWED_ROOM", room.toJson());
      return;
    }
    if (args is Map) {
      if (args['room'] is RoomModel) {
        room = args['room'] as RoomModel;
        _storage.write("LAST_VIEWED_ROOM", room.toJson());
        return;
      }
      try {
        room = RoomModel.fromJson(Map<String, dynamic>.from(args));
        _storage.write("LAST_VIEWED_ROOM", room.toJson());
        return;
      } catch (_) {}
    }

    // Try restoring from storage cache
    final cached = _storage.read("LAST_VIEWED_ROOM");
    if (cached is Map) {
      try {
        room = RoomModel.fromJson(Map<String, dynamic>.from(cached));
        return;
      } catch (_) {}
    }

    // Default fallback room if accessed directly
    room = RoomModel(
      id: 1,
      propertyId: 1,
      propertyName: "Apartment",
      roomNumber: "01",
      title: "បន្ទប់ 01",
      description: "បន្ទប់ស្អាត មានផាសុកភាព សុវត្ថិភាពខ្ពស់",
      price: 50.0,
      area: 18.0,
      floor: 1,
      roomType: "SINGLE",
      genderPreference: "ANY",
      available: true,
      images: null,
    );
  }

  bool get _canEditImages {
    final args = Get.arguments;
    if (args is Map && args.containsKey('canEdit')) {
      return args['canEdit'] == true && TokenStoreLocal.isOwner();
    }
    // Students and guests cannot upload or edit room images; only owners can
    if (TokenStoreLocal.isStudent() || !TokenStoreLocal.isOwner()) {
      return false;
    }
    return true;
  }

  void _openReviewGallery([int index = 0]) {
    if (room.imageList.isNotEmpty) {
      RoomImageSliderWidget.openFullScreenGallery(
        context,
        room.imageList,
        roomNumber: room.roomNumber,
        initialIndex: index,
      );
    }
  }

  void _openChatWithOwner() {
    Get.toNamed(
      AppRouteName.chatDetail,
      arguments: {
        'ownerId': '1',
        'ownerName': LanguageService.isKhmer ? "ម្ចាស់បន្ទប់ (${room.propertyName ?? 'ផ្ទះជួល'})" : "Room Owner (${room.propertyName ?? 'Apartment'})",
        'ownerPhone': "098 765 432",
        'propertyId': room.propertyId,
        'propertyName': room.propertyName,
        'roomId': room.id,
        'roomNumber': room.roomNumber,
        'roomPrice': room.price,
        'initialMessage': LanguageService.isKhmer
            ? "សួស្តីលោកពូ/អ្នកមីង! ខ្ញុំចាប់អារម្មណ៍បន្ទប់ ${room.roomNumber ?? ''} តម្លៃ \$${(room.price ?? 50).toStringAsFixed(0)}/ខែ នៅ ${room.propertyName ?? 'អចលនទ្រព្យ'}។ តើបន្ទប់នេះនៅទំនេរទេបាទ?"
            : "Hello! I am interested in Room ${room.roomNumber ?? ''} for \$${(room.price ?? 50).toStringAsFixed(0)}/mo at ${room.propertyName ?? 'the property'}. Is it still available?",
      },
    );
  }

  Future<void> _updateRoomImages(List<String> newImages) async {
    setState(() => _isUploading = true);

    final String? finalImageStr = newImages.isEmpty
        ? null
        : (newImages.length == 1 ? newImages.first : jsonEncode(newImages));

    final updated = room.copyWith(
      images: finalImageStr,
      updatedAt: DateTime.now().toIso8601String(),
    );

    // 1. Cache to GetStorage
    _storage.write("LAST_VIEWED_ROOM", updated.toJson());
    final propId = updated.propertyId;
    if (propId != null) {
      // Update property room list in cache
      final cachedPropRooms = _storage.read("PROPERTY_ROOMS_$propId");
      if (cachedPropRooms is List) {
        final list = List.from(cachedPropRooms);
        final idx = list.indexWhere((r) => r is Map && (r['id'] == updated.id || r['roomNumber'] == updated.roomNumber));
        if (idx != -1) {
          list[idx] = updated.toJson();
        } else {
          list.add(updated.toJson());
        }
        _storage.write("PROPERTY_ROOMS_$propId", list);
      }

      final ownerKey = TokenStoreLocal.getUserScopedKey("OWNER_ROOMS_$propId");
      final cachedOwnerRooms = _storage.read(ownerKey);
      if (cachedOwnerRooms is List) {
        final list = List.from(cachedOwnerRooms);
        final idx = list.indexWhere((r) => r is Map && (r['id'] == updated.id || r['roomNumber'] == updated.roomNumber));
        if (idx != -1) {
          list[idx] = updated.toJson();
        } else {
          list.add(updated.toJson());
        }
        _storage.write(ownerKey, list);
      }
    }

    // 2. Sync to active controllers in memory
    if (Get.isRegistered<OwnerRoomsController>()) {
      final ctrl = Get.find<OwnerRoomsController>();
      final idx = ctrl.rooms.indexWhere((r) => r.id == updated.id || r.roomNumber == updated.roomNumber);
      if (idx != -1) {
        ctrl.rooms[idx] = updated;
        ctrl.syncToDashboard();
      }
    }

    if (Get.isRegistered<PropertyDetailController>()) {
      final ctrl = Get.find<PropertyDetailController>();
      final idx = ctrl.rooms.indexWhere((r) => r.id == updated.id || r.roomNumber == updated.roomNumber);
      if (idx != -1) {
        ctrl.rooms[idx] = updated;
      }
    }

    // 3. Sync to PostgreSQL Backend API if available
    if (Get.isRegistered<ApiService>() && updated.id != null) {
      try {
        final api = Get.find<ApiService>();
        await api.putApi(
          ConstantUri.roomDetail(updated.id),
          body: {
            'roomNumber': updated.roomNumber ?? '01',
            'title': updated.title ?? 'បន្ទប់ ${updated.roomNumber}',
            'description': updated.description ?? '',
            'price': updated.price ?? 50.0,
            'floor': updated.floor ?? 1,
            'area': updated.area ?? 18.0,
            'roomType': updated.roomType ?? 'SINGLE',
            'available': updated.available ?? true,
            'facilityIds': updated.facilities?.map((f) => f.id).whereType<int>().toList() ?? [1, 2, 3],
            if (finalImageStr != null && finalImageStr.isNotEmpty) 'images': finalImageStr,
          },
        );
      } catch (_) {}
    }

    setState(() {
      room = updated;
      _isUploading = false;
    });

    Get.snackbar(
      LanguageService.isKhmer ? "ជោគជ័យ" : "Success",
      LanguageService.isKhmer ? "រូបថតបន្ទប់ត្រូវបានផ្លាស់ប្តូរជោគជ័យ!" : "Room photo updated successfully!",
      backgroundColor: Colors.green.shade50,
      colorText: Colors.green.shade900,
      icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(12),
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final base64String = "data:image/jpeg;base64,${base64Encode(bytes)}";

      // Upload to server if connected
      _tryUploadFileToServer(file, bytes);

      final current = List<String>.from(room.imageList);
      current.insert(0, base64String);
      await _updateRoomImages(current);
    } catch (e) {
      Get.snackbar("Error", e.toString(), backgroundColor: Colors.red.shade50);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      List<XFile> pickedList = [];
      try {
        pickedList = await _picker.pickMultiImage(
          maxWidth: 1280,
          maxHeight: 1280,
          imageQuality: 85,
        );
      } catch (_) {}

      if (pickedList.isEmpty) {
        final single = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1280,
          maxHeight: 1280,
          imageQuality: 85,
        );
        if (single != null) {
          pickedList = [single];
        }
      }

      if (pickedList.isEmpty) return;

      List<String> newBase64s = [];
      for (var f in pickedList) {
        final bytes = await f.readAsBytes();
        final base64String = "data:image/jpeg;base64,${base64Encode(bytes)}";
        newBase64s.add(base64String);
        _tryUploadFileToServer(f, bytes);
      }

      final current = List<String>.from(room.imageList);
      current.insertAll(0, newBase64s);
      await _updateRoomImages(current);
    } catch (e) {
      Get.snackbar("Error", e.toString(), backgroundColor: Colors.red.shade50);
    }
  }

  Future<void> _tryUploadFileToServer(XFile file, Uint8List bytes) async {
    try {
      final uri = Uri.parse("${ConstantUri.baseUri}/app/public/v1/image/upload");
      final req = http.MultipartRequest("POST", uri);
      if (kIsWeb) {
        req.files.add(http.MultipartFile.fromBytes('File', bytes, filename: file.name));
      } else {
        req.files.add(await http.MultipartFile.fromPath('File', file.path));
      }
      final token = TokenStoreLocal.getAccessToken();
      if (token.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer $token';
      }
      await req.send().timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  void _showUrlInputDialog() {
    final urlCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.link_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              LanguageService.isKhmer ? "បញ្ចូលតំណរូបភាព (URL)" : "Enter Image URL",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LanguageService.isKhmer
                  ? "អ្នកអាចចម្លង និងបិទភ្ជាប់តំណភ្ជាប់រូបភាពពីអ៊ីនធឺណិត (jpg, png, webp)"
                  : "Paste any direct image URL (jpg, png, webp, unsplash, etc.)",
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: "https://example.com/room-photo.jpg",
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.image_outlined, size: 20, color: AppColors.primary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LanguageService.isKhmer ? "បោះបង់" : "Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final text = urlCtrl.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx);
                final current = List<String>.from(room.imageList);
                current.insert(0, text);
                _updateRoomImages(current);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(LanguageService.isKhmer ? "បញ្ចូលរូបភាព" : "Apply Image"),
          ),
        ],
      ),
    );
  }

  void _showUploadImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LanguageService.isKhmer ? "បញ្ចូល ឬប្តូររូបថតបន្ទប់" : "Upload / Change Room Photo",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        LanguageService.isKhmer
                            ? "បន្ទប់ ${room.roomNumber ?? ''} (${room.imageList.length} រូប)"
                            : "Room ${room.roomNumber ?? ''} (${room.imageList.length} photos)",
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Option 1: Camera
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 22),
                ),
                title: Text(
                  LanguageService.isKhmer ? "ថតរូបភាពផ្ទាល់ (Camera)" : "Take a Photo (Camera)",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  LanguageService.isKhmer ? "ប្រើប្រាស់កាមេរ៉ាដើម្បីថតបន្ទប់" : "Use device camera to capture room",
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromCamera();
                },
              ),

              const Divider(height: 1),

              // Option 2: Gallery / Files (Supports Multiple)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Colors.purple, size: 22),
                ),
                title: Text(
                  LanguageService.isKhmer ? "ជ្រើសពីវិចិត្រសាល / ឯកសារ (Files & Gallery)" : "Choose from Files / Gallery",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  LanguageService.isKhmer ? "អាចជ្រើសរើសរូបថតបានច្រើនសន្លឹកក្នុងពេលតែមួយ" : "Select one or multiple photos from device",
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromGallery();
                },
              ),

              const Divider(height: 1),

              // Option 3: Image URL
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.link_rounded, color: Colors.blue, size: 22),
                ),
                title: Text(
                  LanguageService.isKhmer ? "បញ្ចូលតំណភ្ជាប់រូបភាព (Web URL)" : "Enter Web Image URL",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  LanguageService.isKhmer ? "បិទភ្ជាប់តំណរូបភាពពីអ៊ីនធឺណិត (Unsplash, etc.)" : "Paste an online image link directly",
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                onTap: () {
                  Navigator.pop(ctx);
                  _showUrlInputDialog();
                },
              ),

              // Option 4: Clear photos (if exists)
              if (room.imageList.isNotEmpty) ...[
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 22),
                  ),
                  title: Text(
                    LanguageService.isKhmer ? "លុបរូបថតទាំងអស់ចេញ" : "Clear All Room Photos",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.danger),
                  ),
                  subtitle: Text(
                    LanguageService.isKhmer ? "លុបរូបភាពចាស់ ហើយត្រឡប់ទៅរូបដើម" : "Remove current photos from this room",
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Get.defaultDialog(
                      title: LanguageService.isKhmer ? "បញ្ជាក់ការលុប" : "Confirm Clear",
                      middleText: LanguageService.isKhmer
                          ? "តើអ្នកពិតជាចង់លុបរូបថតទាំងអស់នៃបន្ទប់នេះមែនទេ?"
                          : "Are you sure you want to clear photos for this room?",
                      textConfirm: LanguageService.isKhmer ? "លុបចេញ" : "Clear",
                      textCancel: LanguageService.isKhmer ? "បោះបង់" : "Cancel",
                      confirmTextColor: Colors.white,
                      buttonColor: AppColors.danger,
                      onConfirm: () {
                        Get.back();
                        _updateRoomImages([]);
                      },
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      LanguageService.currentLocale.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
            onPressed: () => Get.back(),
          ),
          title: Text(
            "${'room_label_prefix'.tr} ${room.roomNumber ?? ''}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
          ),
          actions: [
            if (_canEditImages) ...[
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_a_photo_outlined, size: 18, color: AppColors.primary),
                ),
                tooltip: LanguageService.isKhmer ? "បញ្ចូល ឬប្តូររូបភាព" : "Upload or change image",
                onPressed: _showUploadImageOptions,
              ),
              const SizedBox(width: 8),
            ] else ...[
              if (room.imageList.isNotEmpty) ...[
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fullscreen_rounded, size: 20, color: AppColors.primary),
                  ),
                  tooltip: LanguageService.isKhmer ? "ពិនិត្យមើលរូបភាព" : "Review photos",
                  onPressed: () => _openReviewGallery(0),
                ),
                const SizedBox(width: 4),
              ],
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.primary),
                ),
                tooltip: LanguageService.isKhmer ? "ឆាតជាមួយម្ចាស់បន្ទប់" : "Chat with Owner",
                onPressed: _openChatWithOwner,
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Photo / Multi-Photo Slider Header with Interactive Upload (Only for Owner)
              RoomImageSliderWidget(
                images: room.imageList,
                roomNumber: room.roomNumber,
                height: 240,
                heroTag: 'room_hero_${room.id ?? room.roomNumber}',
                onAddOrChangePhoto: _canEditImages ? _showUploadImageOptions : null,
                isUploading: _isUploading,
                fallback: Container(
                  color: AppColors.primarySoft,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.meeting_room_rounded, size: 56, color: AppColors.primary.withValues(alpha: 0.7)),
                        const SizedBox(height: 8),
                        Text(
                          room.title ?? "${'room_label_prefix'.tr} ${room.roomNumber ?? ''}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                        ),
                        if (_canEditImages) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_a_photo_outlined, size: 14, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  LanguageService.isKhmer ? "ចុចដើម្បីបញ្ចូលរូបថតបន្ទប់" : "Tap to upload room photo",
                                  style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 6),
                          Text(
                            LanguageService.isKhmer ? "មិនទាន់មានរូបភាពបន្ទប់នៅឡើយទេ" : "No photos available",
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Room Photos Card (Owner can upload/change, Student can review/view)
              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: (!_canEditImages && room.imageList.isNotEmpty)
                      ? () => _openReviewGallery(0)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _canEditImages ? Icons.photo_camera_back_outlined : Icons.photo_library_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LanguageService.isKhmer ? "រូបថតបន្ទប់" : "Room Photos",
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              Text(
                                room.imageList.isEmpty
                                    ? (_canEditImages
                                        ? (LanguageService.isKhmer ? "មិនទាន់មានរូបថត (ចុចដើម្បីបញ្ចូល)" : "No photos yet (tap to upload)")
                                        : (LanguageService.isKhmer ? "មិនទាន់មានរូបថតនៅឡើយទេ" : "No photos available yet"))
                                    : (_canEditImages
                                        ? (LanguageService.isKhmer ? "មាន ${room.imageList.length} រូបថត" : "${room.imageList.length} photos uploaded")
                                        : (LanguageService.isKhmer ? "មាន ${room.imageList.length} រូបថត (ចុចដើម្បីពិនិត្យមើល)" : "${room.imageList.length} photos (tap to review)")),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: room.imageList.isEmpty ? Colors.amber.shade800 : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_canEditImages) ...[
                          ElevatedButton.icon(
                            onPressed: _isUploading ? null : _showUploadImageOptions,
                            icon: const Icon(Icons.add_photo_alternate_outlined, size: 14),
                            label: Text(
                              room.imageList.isEmpty
                                  ? (LanguageService.isKhmer ? "បញ្ចូលរូប" : "Upload")
                                  : (LanguageService.isKhmer ? "ប្តូរ / បន្ថែម" : "Change"),
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                          ),
                        ] else if (room.imageList.isNotEmpty) ...[
                          ElevatedButton.icon(
                            onPressed: () => _openReviewGallery(0),
                            icon: const Icon(Icons.remove_red_eye_outlined, size: 14),
                            label: Text(
                              LanguageService.isKhmer ? "ពិនិត្យមើល" : "Review",
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primarySoft,
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Price & Availability Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('price_per_month'.tr, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(
                          "\$${(room.price ?? 0).toStringAsFixed(0)} / mo",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (room.available ?? true) ? AppColors.primarySoft : AppColors.dangerSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        (room.available ?? true) ? 'available'.tr : 'occupied'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: (room.available ?? true) ? AppColors.primary : AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Room Specifications Grid
              Text('room_specifications'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSpecItem(
                      'floor_spec'.tr,
                      room.floorDisplayName,
                      Icons.layers_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSpecItem(
                      'area_spec'.tr,
                      "${room.area ?? 18} m²",
                      Icons.aspect_ratio_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildSpecItem(
                      'type_spec'.tr,
                      room.roomTypeDisplayName,
                      Icons.king_bed_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSpecItem(
                      'gender_spec'.tr,
                      room.genderPreferenceDisplayName,
                      Icons.people_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Description
              if (room.description != null && room.description!.isNotEmpty) ...[
                Text('description'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                Text(
                  room.description!,
                  style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
              ],

              // Facilities
              Text('room_facilities'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              if (room.facilities != null && room.facilities!.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: room.facilities!.map((f) => FacilityChip(name: f.name ?? '')).toList(),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    FacilityChip(name: "WIFI"),
                    FacilityChip(name: "AIR_CONDITIONER"),
                    FacilityChip(name: "PRIVATE_BATHROOM"),
                  ],
                ),

              const SizedBox(height: 32),

              // Action Buttons
              if (!_canEditImages) ...[
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _openChatWithOwner,
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                      label: Text(
                        LanguageService.isKhmer ? "ឆាតជាមួយម្ចាស់" : "Chat",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => RequestVisitDialog(
                              propertyId: room.propertyId ?? 1,
                              roomId: room.id,
                              roomNumber: room.roomNumber,
                              propertyName: room.propertyName ?? "Property",
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_month_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'request_visit_for_room'.tr,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => RequestVisitDialog(
                        propertyId: room.propertyId ?? 1,
                        roomId: room.id,
                        roomNumber: room.roomNumber,
                        propertyName: room.propertyName ?? "Property",
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'request_visit_for_room'.tr,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSpecItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
