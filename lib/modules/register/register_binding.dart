import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import 'register_controller.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RegisterController(apiService: Get.find<ApiService>()));
  }
}
