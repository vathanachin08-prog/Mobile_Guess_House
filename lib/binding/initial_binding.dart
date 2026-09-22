import 'package:demo_access_refresh_token_app/core/services/api_service.dart';
import 'package:demo_access_refresh_token_app/core/services/api_service_impl.dart';
import 'package:demo_access_refresh_token_app/modules/home/home_controller.dart';
import 'package:demo_access_refresh_token_app/modules/login/login_controller.dart';
import 'package:demo_access_refresh_token_app/modules/splash/splash_controller.dart';
import 'package:get/get.dart';
import 'package:get/get_instance/src/bindings_interface.dart';

import '../modules/post/post_form_controller.dart';

class InitialBinding extends Bindings{
  @override
  void dependencies() {
    Get.lazyPut<ApiService>(()=> ApiServiceImpl(), fenix: true);
  }

}