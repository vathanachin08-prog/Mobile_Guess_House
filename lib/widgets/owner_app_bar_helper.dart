import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../constants/constant_uri.dart';
import '../core/services/language_service.dart';
import '../data/local/token_store_local.dart';
import '../modules/owner/owner_main_controller.dart';
import '../routes/app_route_name.dart';
import 'app_colors.dart';

class OwnerAppBarHelper {
  OwnerAppBarHelper._();

  static OwnerMainController getController() {
    if (Get.isRegistered<OwnerMainController>()) {
      return Get.find<OwnerMainController>();
    }
    return Get.put(OwnerMainController());
  }

  /// Show property switcher bottom sheet
  static void showPropertyPicker(BuildContext context) {
    final ctrl = getController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'select_property'.tr,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'switch_active_building'.tr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 22),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Property List
                Obx(() {
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ctrl.propertiesList.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = ctrl.propertiesList[index];
                      final isSelected = item['id'] == ctrl.selectedPropertyId.value;

                      return InkWell(
                        onTap: () {
                          ctrl.selectProperty(item);
                          Navigator.pop(ctx);
                          Get.snackbar(
                            'select_property'.tr,
                            "${'switch_active_building'.tr}: ${item['name']}",
                            snackPosition: SnackPosition.BOTTOM,
                            margin: const EdgeInsets.all(16),
                            backgroundColor: Colors.white,
                            colorText: AppColors.textPrimary,
                            icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                            duration: const Duration(seconds: 2),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primarySoft.withValues(alpha: 0.35) : AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildPropertyThumbnail(item['mainImage'] as String?, isSelected),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] as String,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${item['address']} • ${item['rooms']} ${'rooms'.tr}",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),

                const SizedBox(height: 16),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 14),

                // Add Property Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showAddPropertyDialog(context, ctrl, ctx);
                    },
                    icon: const Icon(Icons.add_business_rounded, size: 18, color: AppColors.primary),
                    label: Text(
                      'add_new_property_btn'.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.primary, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Helper to render property thumbnail or default fallback icon
  static Widget _buildPropertyThumbnail(String? imageSource, bool isSelected) {
    if (imageSource != null && imageSource.trim().isNotEmpty) {
      Widget imgWidget;
      if (imageSource.startsWith('data:image')) {
        try {
          final base64Str = imageSource.split(',').last;
          imgWidget = Image.memory(
            base64Decode(base64Str),
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => Icon(
              Icons.business_rounded,
              size: 20,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          );
        } catch (_) {
          imgWidget = Icon(
            Icons.business_rounded,
            size: 20,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          );
        }
      } else {
        final fullUrl = imageSource.startsWith('http')
            ? imageSource
            : "${ConstantUri.baseUri}/api/public/view/image?filename=$imageSource";
        imgWidget = Image.network(
          fullUrl,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => Icon(
            Icons.business_rounded,
            size: 20,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 42,
          height: 42,
          color: AppColors.primarySoft,
          child: imgWidget,
        ),
      );
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.business_rounded,
        size: 20,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
    );
  }

  /// Bottom sheet to choose image source (Camera vs Gallery)
  static void _showImageSourceSheet({
    required BuildContext context,
    required Function(ImageSource source) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'choose_image_source'.tr,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: Text('take_photo'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('use_camera'.tr, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                onTap: () {
                  Navigator.pop(ctx);
                  onSelect(ImageSource.camera);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                ),
                title: Text('choose_gallery'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('select_from_device'.tr, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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

  /// Show Add Property Dialog with Image Upload support
  static void _showAddPropertyDialog(BuildContext context, OwnerMainController ctrl, BuildContext sheetContext) {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final ImagePicker picker = ImagePicker();

    XFile? pickedFile;
    Uint8List? pickedBytes;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          title: Row(
            children: [
              const Icon(Icons.add_business_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'add_new_property_btn'.tr,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Picker Container
                InkWell(
                  onTap: isSaving
                      ? null
                      : () {
                          _showImageSourceSheet(
                            context: dialogCtx,
                            onSelect: (source) async {
                              try {
                                final img = await picker.pickImage(
                                  source: source,
                                  maxWidth: 1024,
                                  maxHeight: 1024,
                                  imageQuality: 85,
                                );
                                if (img != null) {
                                  final bytes = await img.readAsBytes();
                                  setDialogState(() {
                                    pickedFile = img;
                                    pickedBytes = bytes;
                                  });
                                }
                              } catch (e) {
                                Get.snackbar(
                                  'error'.tr,
                                  e.toString(),
                                  backgroundColor: Colors.red.shade50,
                                );
                              }
                            },
                          );
                        },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    height: pickedBytes != null ? 130 : 96,
                    decoration: BoxDecoration(
                      color: pickedBytes != null
                          ? Colors.black12
                          : AppColors.primarySoft.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: pickedBytes != null
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: pickedBytes != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  pickedBytes!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.65),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'change_photo'.tr,
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () {
                                        setDialogState(() {
                                          pickedFile = null;
                                          pickedBytes = null;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_photo_alternate_rounded,
                                size: 32,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'upload_property_image'.tr,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'tap_to_upload_image'.tr,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 14),

                // Name Input
                TextField(
                  controller: nameCtrl,
                  enabled: !isSaving,
                  decoration: InputDecoration(
                    labelText: 'property_name_label'.tr,
                    hintText: LanguageService.isKhmer ? "ឧ. Rose Garden Apartment" : "e.g. Rose Garden Apartment",
                    prefixIcon: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Address Input
                TextField(
                  controller: addressCtrl,
                  enabled: !isSaving,
                  decoration: InputDecoration(
                    labelText: 'property_address_label'.tr,
                    hintText: LanguageService.isKhmer ? "ឧ. ខណ្ឌដូនពេញ រាជធានីភ្នំពេញ" : "e.g. Khan Daun Penh, Phnom Penh",
                    prefixIcon: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
              child: Text('cancel'.tr, style: const TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final addr = addressCtrl.text.trim();
                      if (name.isEmpty) {
                        Get.snackbar(
                          'confirm'.tr,
                          'please_enter_property_name'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.white,
                          colorText: AppColors.danger,
                          margin: const EdgeInsets.all(16),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);

                      String? uploadedImageUrl;

                      if (pickedFile != null && pickedBytes != null) {
                        try {
                          final uri = Uri.parse("${ConstantUri.baseUri}/app/public/v1/image/upload");
                          final req = http.MultipartRequest("POST", uri);
                          if (kIsWeb) {
                            req.files.add(http.MultipartFile.fromBytes('File', pickedBytes!, filename: pickedFile!.name));
                          } else {
                            req.files.add(await http.MultipartFile.fromPath('File', pickedFile!.path));
                          }
                          final token = TokenStoreLocal.getAccessToken();
                          if (token.isNotEmpty) {
                            req.headers['Authorization'] = 'Bearer $token';
                          }
                          final streamed = await req.send().timeout(const Duration(seconds: 15));
                          final res = await http.Response.fromStream(streamed);
                          if (res.statusCode == 200 || res.statusCode == 201) {
                            final decoded = jsonDecode(utf8.decode(res.bodyBytes));
                            final data = decoded['data'];
                            if (data != null && data['fileName'] != null) {
                              final fileName = data['fileName'].toString();
                              uploadedImageUrl = "${ConstantUri.baseUri}/api/public/view/image?filename=$fileName";
                            }
                          }
                        } catch (e) {
                          debugPrint("Error uploading property image: $e");
                        }

                        // Fallback to base64 so image preview is never lost
                        uploadedImageUrl ??= "data:image/jpeg;base64,${base64Encode(pickedBytes!)}";
                      }

                      await ctrl.addNewProperty(
                        name,
                        addr.isNotEmpty ? addr : "Phnom Penh",
                        mainImage: uploadedImageUrl,
                      );

                      if (dialogCtx.mounted) {
                        Navigator.pop(dialogCtx);
                      }
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }

                      Get.snackbar(
                        'success'.tr,
                        'property_created_success'.tr,
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.white,
                        colorText: AppColors.textPrimary,
                        icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                        margin: const EdgeInsets.all(16),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('save'.tr),
            ),
          ],
        ),
      ),
    );
  }

  /// Show notifications modal bottom sheet
  static void showNotifications(BuildContext context) {
    final ctrl = getController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'notifications'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Obx(() {
                      final count = ctrl.unreadNotificationsCount.value;
                      if (count > 0) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'new_notifications_count'.trParams({'count': count.toString()}),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.danger,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Mark all read button row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        ctrl.markAllNotificationsAsRead();
                        Get.snackbar(
                          'notifications'.tr,
                          'all_marked_read'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.white,
                          colorText: AppColors.textPrimary,
                          margin: const EdgeInsets.all(16),
                        );
                      },
                      icon: const Icon(Icons.done_all_rounded, size: 16, color: AppColors.primary),
                      label: Text(
                        'mark_all_read'.tr,
                        style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 8),

                // Notification Items List
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.55,
                  ),
                  child: Obx(() {
                    if (ctrl.notificationsList.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text('no_notifications'.tr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: ctrl.notificationsList.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final notif = ctrl.notificationsList[index];
                        final isUnread = notif['isUnread'] == true;
                        final color = (notif['color'] as Color?) ?? AppColors.primary;
                        final icon = (notif['icon'] as IconData?) ?? Icons.notifications_rounded;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              final id = notif['id']?.toString() ?? '';
                              ctrl.markNotificationAsRead(id);
                              Navigator.pop(ctx);
                              if (notif['route'] != null) {
                                Get.toNamed(notif['route'] as String);
                              } else if (notif['tabIndex'] != null) {
                                ctrl.changeTab(notif['tabIndex'] as int);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUnread ? color.withValues(alpha: 0.05) : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isUnread ? color.withValues(alpha: 0.3) : AppColors.border,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(icon, size: 18, color: color),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notif['title'] as String,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              notif['time'] as String,
                                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                            ),
                                            if (isUnread) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                width: 7,
                                                height: 7,
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          notif['message'] as String,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                            height: 1.3,
                                          ),
                                        ),
                                        if (notif['route'] != null || notif['tabIndex'] != null) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Text(
                                                'view_details_link'.tr,
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(Icons.arrow_forward_rounded, size: 12, color: color),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
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
          ),
        );
      },
    );
  }

  /// Navigate to owner account / profile tab
  static void navigateToProfile(BuildContext context) {
    if (Get.isRegistered<OwnerMainController>()) {
      final mainCtrl = Get.find<OwnerMainController>();
      mainCtrl.changeTab(5); // Index 5 is OwnerProfileView
      if (Navigator.canPop(context)) {
        Get.until((route) => route.isFirst);
      }
    } else {
      Get.toNamed(AppRouteName.ownerProfile);
    }
  }

  /// Build notification icon with real-time unread badge
  static Widget buildNotificationAction(BuildContext context) {
    final ctrl = getController();

    return Obx(() {
      final unread = ctrl.unreadNotificationsCount.value;

      return IconButton(
        tooltip: 'notifications'.tr,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 24),
            if (unread > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                ),
              ),
          ],
        ),
        onPressed: () => showNotifications(context),
      );
    });
  }

  /// Build language switcher action
  static Widget buildLanguageAction(BuildContext context) {
    return IconButton(
      tooltip: 'switch_language'.tr,
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, color: AppColors.primary, size: 15),
            const SizedBox(width: 4),
            Text(
              LanguageService.isKhmer ? "KH" : "EN",
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
      onPressed: () => LanguageService.showLanguageSelector(context),
    );
  }

  /// Build account (profile) icon action
  static Widget buildAccountAction(BuildContext context) {
    return IconButton(
      tooltip: 'profile'.tr,
      icon: const Icon(Icons.person_outline_rounded, color: AppColors.textPrimary, size: 24),
      onPressed: () => navigateToProfile(context),
    );
  }

  /// Standard owner action widgets (Language + Notification + Account)
  static List<Widget> buildStandardActions(BuildContext context) {
    return [
      buildLanguageAction(context),
      buildNotificationAction(context),
      buildAccountAction(context),
      const SizedBox(width: 4),
    ];
  }
}
