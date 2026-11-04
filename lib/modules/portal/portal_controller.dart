import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/local/token_store_local.dart';
import '../../repositories/auth_repository.dart';
import '../../routes/app_route_name.dart';
import '../../widgets/app_colors.dart';

class PortalController extends GetxController {
  final AuthRepository authRepository;

  PortalController({required this.authRepository});

  final currentIndex = 0.obs;
  final user = Rxn<Map<String, dynamic>>();
  final userRole = ''.obs;
  final accessToken = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  void loadUserData() {
    user.value = TokenStoreLocal.getUser();
    userRole.value = TokenStoreLocal.getUserRole();
    accessToken.value = TokenStoreLocal.getAccessToken();
  }

  void changeTab(int index) {
    currentIndex.value = index;
  }

  void confirmLogout(BuildContext context) {
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
                child: Icon(Icons.logout_rounded, color: Colors.red.shade600, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to log out of your session? You will need to log in again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
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
                        await authRepository.logout();
                        Get.offAllNamed(AppRouteName.login);
                        Get.snackbar(
                          'Logged Out',
                          'You have been successfully logged out',
                          backgroundColor: Colors.blue.shade50,
                          colorText: Colors.blue.shade900,
                          icon: const Icon(Icons.info_outline_rounded, color: Colors.blue),
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(16),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
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
}

