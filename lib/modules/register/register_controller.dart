import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import '../../core/services/firebase_service.dart';
import '../../models/login/LoginRequest.dart';
import '../../data/local/token_store_local.dart';
import '../../routes/app_route_name.dart';

class RegisterController extends GetxController {
  final ApiService apiService;
  RegisterController({required this.apiService});

  final usernameController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final selectedRole = "STUDENT".obs; // STUDENT or OWNER
  final isLoading = false.obs;
  final obscurePassword = true.obs;

  @override
  void onClose() {
    usernameController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void onRegister() async {
    final phone = phoneController.text.trim();
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final username = usernameController.text.trim().isNotEmpty ? usernameController.text.trim() : phone;

    if (firstName.isEmpty || lastName.isEmpty) {
      AppFirebaseService.logRegisterForm(success: false, role: selectedRole.value, errorMessage: "Missing first or last name");
      Get.snackbar("Error", "Please enter your first and last name", backgroundColor: Colors.red.shade50);
      return;
    }
    if (phone.isEmpty) {
      AppFirebaseService.logRegisterForm(success: false, role: selectedRole.value, errorMessage: "Missing phone number");
      Get.snackbar("Error", "Phone number is required", backgroundColor: Colors.red.shade50);
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      AppFirebaseService.logRegisterForm(success: false, role: selectedRole.value, errorMessage: "Invalid email");
      Get.snackbar("Error", "Valid email address is required", backgroundColor: Colors.red.shade50);
      return;
    }
    if (password.isEmpty || password.length < 6) {
      AppFirebaseService.logRegisterForm(success: false, role: selectedRole.value, errorMessage: "Password too short");
      Get.snackbar("Error", "Password must be at least 6 characters", backgroundColor: Colors.red.shade50);
      return;
    }
    if (password != confirmPassword) {
      AppFirebaseService.logRegisterForm(success: false, role: selectedRole.value, errorMessage: "Passwords mismatch");
      Get.snackbar("Error", "Passwords do not match", backgroundColor: Colors.red.shade50);
      return;
    }

    isLoading.value = true;
    try {
      final body = {
        "username": username,
        "firstName": firstName,
        "lastName": lastName,
        "phoneNumber": phone,
        "email": email,
        "password": password,
        "confirmPassword": confirmPassword,
        "role": selectedRole.value,
      };

      final response = await apiService.register(body: body);
      if (response != null && (response['code'] == "200" || response['code'] == 200 || response['status'] == 200)) {
        // Track register success
        AppFirebaseService.logRegisterForm(success: true, role: selectedRole.value);
        Get.snackbar("Success", "Account created successfully! Logging in...", backgroundColor: Colors.green.shade50);

        // Auto login after registration
        final loginRes = await apiService.login(
          body: LoginRequest(phoneNumber: phone, password: password),
        );
        if (loginRes.accessToken != null && loginRes.accessToken!.isNotEmpty) {
          TokenStoreLocal.setAccessToken(loginRes.accessToken ?? "");
          TokenStoreLocal.setRefreshToken(loginRes.refreshToken ?? "");
          if (loginRes.user != null) {
            TokenStoreLocal.setUser(loginRes.user!.toJson());
          }
          if (TokenStoreLocal.isOwner()) {
            Get.offAllNamed(AppRouteName.ownerMain);
          } else {
            Get.offAllNamed(AppRouteName.studentMain);
          }
        } else {
          Get.offAllNamed(AppRouteName.login);
        }
      } else {
        final msg = response != null ? (response['message'] ?? response['error']) : "Registration failed";
        AppFirebaseService.logRegisterForm(success: false, role: selectedRole.value, errorMessage: msg.toString());
        Get.snackbar("Error", "$msg", backgroundColor: Colors.red.shade50);
      }
    } catch (e) {
      AppFirebaseService.logRegisterForm(success: false, role: selectedRole.value, errorMessage: e.toString());
      Get.snackbar("Error", "Registration failed: $e", backgroundColor: Colors.red.shade50);
    } finally {
      isLoading.value = false;
    }
  }
}
