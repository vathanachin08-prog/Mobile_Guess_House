
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/api_service.dart';
import '../../data/local/token_store_local.dart';
import '../../models/login/LoginRequest.dart';
import '../../routes/app_route_name.dart';

class LoginController extends GetxController {
  final ApiService apiService;
  LoginController({required this.apiService});

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;
  final obscurePassword = true.obs;

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void onLogin() async {
    String username = usernameController.text.trim();
    String password = passwordController.text.trim();
    if (username.isEmpty) {
      Get.snackbar("Error", "Phone number is required", backgroundColor: Colors.red.shade50);
      return;
    }
    if (password.isEmpty) {
      Get.snackbar("Error", "Password is required", backgroundColor: Colors.red.shade50);
      return;
    }
    isLoading.value = true;
    try {
      final loginResponse = await apiService.login(
        body: LoginRequest(phoneNumber: username, password: password),
      );
      if (loginResponse.accessToken != null && loginResponse.accessToken!.isNotEmpty) {
        TokenStoreLocal.setAccessToken(loginResponse.accessToken ?? "");
        TokenStoreLocal.setRefreshToken(loginResponse.refreshToken ?? "");
        if (loginResponse.user != null) {
          TokenStoreLocal.setUser(loginResponse.user!.toJson());
        }

        Get.snackbar("Success", "Login Successfully", backgroundColor: Colors.green.shade50);

        if (TokenStoreLocal.isOwner()) {
          Get.offAllNamed(AppRouteName.ownerMain);
        } else {
          Get.offAllNamed(AppRouteName.studentMain);
        }
      } else {
        Get.snackbar(
          "Error",
          "Invalid phone number or password",
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      Get.snackbar("Error", "Connection failed: $e", backgroundColor: Colors.red.shade50);
    } finally {
      isLoading.value = false;
    }
  }
}
