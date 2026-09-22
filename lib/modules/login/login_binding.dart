import 'package:demo_access_refresh_token_app/core/services/api_service.dart';
import 'package:demo_access_refresh_token_app/modules/login/login_controller.dart';
import 'package:get/get.dart';

import '../../core/services/api_service_impl.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(()=> LoginController(
      apiService: Get.find<ApiService>()
    ));
  }

}