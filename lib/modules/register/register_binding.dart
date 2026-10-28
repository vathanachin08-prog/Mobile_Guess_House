import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import '../../core/services/api_service_impl.dart';
import 'register_controller.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ApiService>()) {
      Get.put<ApiService>(ApiServiceImpl(), permanent: true);
    }
    Get.lazyPut(() => RegisterController(apiService: Get.find<ApiService>()), fenix: true);
  }
}
