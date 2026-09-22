
import 'package:demo_access_refresh_token_app/core/services/api_service_impl.dart';
import 'package:demo_access_refresh_token_app/routes/app_route_name.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../core/services/api_service.dart';
import '../../data/local/token_store_local.dart';
import '../../models/login/LoginRequest.dart';

class LoginController extends GetxController {
  final ApiService apiService;
  LoginController({required this.apiService});
  var usernameController = TextEditingController().obs;
  var passwordController = TextEditingController().obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
  }

  void onLogin() async {
    String username = usernameController.value.text.trim();
    String password = passwordController.value.text.trim();
    if (username.isEmpty) {
      Get.snackbar("Error", "Username is required");
      return;
    }
    if (password.isEmpty) {
      Get.snackbar("Error", "Password is required");
      return;
    }
    isLoading.value = true;
    var loginResponse = await apiService.login(
      body: LoginRequest(phoneNumber: username, password: password),
    );
    if (loginResponse.accessToken != null) {
      Get.snackbar("Success", "Login Successfully");
      TokenStoreLocal.setAccessToken(loginResponse.accessToken ?? "");
      TokenStoreLocal.setRefreshToken(loginResponse.refreshToken ?? "");
      Get.offNamed(AppRouteName.home);
    } else {
      Get.snackbar("Error", "Login Un Successfully");
    }
    isLoading.value = false;
  }
}
