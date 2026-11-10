import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/language_service.dart';
import '../../models/login/LoginRequest.dart';
import '../../data/local/token_store_local.dart';
import '../../routes/app_route_name.dart';
import '../../widgets/app_colors.dart';

class RegisterController extends GetxController {
  final ApiService apiService;
  RegisterController({required this.apiService});

  // Basic User Controllers
  TextEditingController usernameController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  // Additional Owner Details Controllers
  TextEditingController propertyNameController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController idCardController = TextEditingController();
  TextEditingController totalRoomsController = TextEditingController(text: "8");

  final selectedRole = "STUDENT".obs; // STUDENT or OWNER
  final isLoading = false.obs;
  final obscurePassword = true.obs;

  void ensureControllers() {
    // Kept safe: do not replace active controllers to prevent wiping user input
  }

  void resetForm() {
    usernameController.clear();
    firstNameController.clear();
    lastNameController.clear();
    phoneController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    propertyNameController.clear();
    addressController.clear();
    idCardController.clear();
    totalRoomsController.text = "8";
    isLoading.value = false;
    obscurePassword.value = true;
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

    final isOwner = selectedRole.value == "OWNER";
    final propertyName = propertyNameController.text.trim();
    final address = addressController.text.trim();
    final idCard = idCardController.text.trim();
    final totalRooms = totalRoomsController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      AppFirebaseService.logRegisterForm(success: false, role: selectedRole.value, errorMessage: "Missing first or last name");
      Get.snackbar("Error", LanguageService.isKhmer ? "សូមបញ្ចូលនាមត្រកូល និងនាមខ្លួន!" : "Please enter your first and last name", backgroundColor: Colors.red.shade50);
      return;
    }
    if (phone.isEmpty) {
      AppFirebaseService.logRegisterForm(success: false, role: selectedRole.value, errorMessage: "Missing phone number");
      Get.snackbar("Error", LanguageService.isKhmer ? "សូមបញ្ចូលលេខទូរស័ព្ទ!" : "Phone number is required", backgroundColor: Colors.red.shade50);
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      AppFirebaseService.logRegisterForm(success: false, role: selectedRole.value, errorMessage: "Invalid email");
      Get.snackbar("Error", LanguageService.isKhmer ? "សូមបញ្ចូលអ៊ីមែលត្រឹមត្រូវ!" : "Valid email address is required", backgroundColor: Colors.red.shade50);
      return;
    }
    if (password.isEmpty || password.length < 6) {
      AppFirebaseService.logRegisterForm(success: false, role: selectedRole.value, errorMessage: "Password too short");
      Get.snackbar("Error", LanguageService.isKhmer ? "ពាក្យសម្ងាត់ត្រូវមានយ៉ាងហោចណាស់ ៦ ខ្ទង់!" : "Password must be at least 6 characters", backgroundColor: Colors.red.shade50);
      return;
    }
    if (password != confirmPassword) {
      AppFirebaseService.logRegisterForm(success: false, role: selectedRole.value, errorMessage: "Passwords mismatch");
      Get.snackbar("Error", LanguageService.isKhmer ? "ពាក្យសម្ងាត់ផ្ទៀងផ្ទាត់មិនត្រូវគ្នាទេ!" : "Passwords do not match", backgroundColor: Colors.red.shade50);
      return;
    }

    // Owner specific field validations
    if (isOwner) {
      if (propertyName.isEmpty) {
        Get.snackbar("Error", LanguageService.isKhmer ? "សូមបញ្ចូលឈ្មោះអគារ ឬបន្ទប់ជួល!" : "Please enter your property name", backgroundColor: Colors.red.shade50);
        return;
      }
      if (address.isEmpty) {
        Get.snackbar("Error", LanguageService.isKhmer ? "សូមបញ្ចូលទីតាំងអគារបន្ទប់ជួល!" : "Please enter property address/location", backgroundColor: Colors.red.shade50);
        return;
      }
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
        if (isOwner) ...{
          "propertyName": propertyName,
          "address": address,
          "idCard": idCard,
          "totalRooms": totalRooms,
        }
      };

      final response = await apiService.register(body: body);
      if (response != null && (response['code'] == "200" || response['code'] == 200 || response['status'] == 200)) {
        // Track register success
        AppFirebaseService.logRegisterForm(success: true, role: selectedRole.value);

        if (isOwner) {
          // OWNER FLOW: Do NOT redirect to ownerMain. Send to Web Admin for approval!
          _showOwnerPendingApprovalDialog();
        } else {
          // STUDENT FLOW: Auto login and redirect directly to studentMain app!
          Get.snackbar("Success", LanguageService.isKhmer ? "បង្កើតគណនីនិស្សិតបានជោគជ័យ! កំពុងចូលប្រព័ន្ធ..." : "Student account created successfully! Logging in...", backgroundColor: Colors.green.shade50);

          final loginRes = await apiService.login(
            body: LoginRequest(phoneNumber: phone, password: password),
          );
          if (loginRes.accessToken != null && loginRes.accessToken!.isNotEmpty) {
            TokenStoreLocal.removeToken(redirect: false);
            TokenStoreLocal.setAccessToken(loginRes.accessToken ?? "");
            TokenStoreLocal.setRefreshToken(loginRes.refreshToken ?? "");
            final registeredUser = (response is Map && response['data'] is Map)
                ? Map<String, dynamic>.from(response['data'])
                : <String, dynamic>{};
            final userData = loginRes.user?.toJson() ?? {
              "id": registeredUser['id'],
              "username": username,
              "phoneNumber": phone,
              "firstName": firstName,
              "lastName": lastName,
              "email": email,
              "roles": [{"name": "STUDENT"}],
            };
            TokenStoreLocal.setUser(userData);
            Get.offAllNamed(AppRouteName.studentMain);
          } else {
            Get.offAllNamed(AppRouteName.login);
          }
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

  void _showOwnerPendingApprovalDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 26.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
                ),
                child: const Icon(Icons.verified_user_rounded, color: Color(0xFF00A86B), size: 38),
              ),
              const SizedBox(height: 18),
              Text(
                LanguageService.isKhmer ? "បានបញ្ជូនព័ត៌មានរួចរាល់!" : "Application Submitted!",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                LanguageService.isKhmer
                    ? "ព័ត៌មានចុះឈ្មោះជាម្ចាស់ផ្ទះរបស់លោកអ្នក ត្រូវបានបញ្ជូនទៅកាន់ Web Admin រួចរាល់ហើយ។\n\nសូមរង់ចាំការត្រួតពិនិត្យ និងអនុម័តពី Admin (Web Admin Approval) មុនពេលលោកអ្នកអាចចូលប្រើប្រាស់បាន។"
                    : "Your owner application has been submitted to the Web Admin.\n\nPlease wait for Admin review and approval before logging in to manage your properties.",
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.45),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A86B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Get.back(); // close dialog
                    resetForm();
                    Get.offAllNamed(AppRouteName.login);
                  },
                  child: Text(
                    LanguageService.isKhmer ? "ត្រឡប់ទៅផ្ទាំងចូលប្រើ (Log in)" : "Back to Login",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
