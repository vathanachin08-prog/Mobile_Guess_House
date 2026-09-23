import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/local/token_store_local.dart';
import '../../../routes/app_route_name.dart';

class StudentProfileController extends GetxController {
  final user = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    loadUser();
  }

  void loadUser() {
    user.value = TokenStoreLocal.getUser();
  }

  String get displayName {
    final u = user.value;
    if (u != null) {
      final f = u['firstName'] ?? '';
      final l = u['lastName'] ?? '';
      if (f.isNotEmpty) return "$f $l".trim();
      return u['username'] ?? 'Student';
    }
    return 'Student';
  }

  String get phone => user.value?['phoneNumber'] ?? '012345678';
  String get email => user.value?['email'] ?? 'student@example.com';

  void toggleLanguage() {
    if (Get.locale?.languageCode == 'km') {
      Get.updateLocale(const Locale('en', 'US'));
    } else {
      Get.updateLocale(const Locale('km', 'KH'));
    }
  }

  void logout() {
    TokenStoreLocal.removeToken();
    Get.offAllNamed(AppRouteName.login);
  }
}
