import 'package:demo_access_refresh_token_app/data/local/token_store_local.dart';
import 'package:demo_access_refresh_token_app/routes/app_route_name.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  var isLoading = false.obs;
  @override
  void onInit() {
    _checkToken();
    super.onInit();
  }

  Future<void> _checkToken() async {
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 1500));
    if (TokenStoreLocal.getAccessToken().isNotEmpty) {
      if (TokenStoreLocal.isOwner()) {
        Get.offAllNamed(AppRouteName.ownerMain);
      } else {
        Get.offAllNamed(AppRouteName.studentMain);
      }
    } else {
      Get.offAllNamed(AppRouteName.login);
    }
    isLoading.value = false;
  }
}
