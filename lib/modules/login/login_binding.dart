import 'package:demo_access_refresh_token_app/core/services/api_service.dart';
import 'package:demo_access_refresh_token_app/core/services/api_service_impl.dart';
import 'package:demo_access_refresh_token_app/modules/login/login_controller.dart';
import 'package:get/get.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ApiService>()) {
      Get.put<ApiService>(ApiServiceImpl(), permanent: true);
    }
    Get.lazyPut<LoginController>(
      () => LoginController(
        apiService: Get.find<ApiService>(),
      ),
      fenix: true,
    );
  }
}