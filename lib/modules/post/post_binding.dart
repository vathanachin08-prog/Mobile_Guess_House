import 'package:demo_access_refresh_token_app/core/services/api_service.dart';
import 'package:demo_access_refresh_token_app/modules/post/post_controller.dart';
import 'package:get/get.dart';
import 'package:get/get_instance/src/bindings_interface.dart';

class PostBinding extends Bindings{
  @override
  void dependencies() {
    Get.lazyPut(()=> PostController(
      apiService: Get.find<ApiService>()
    ), fenix: true);
  }

}