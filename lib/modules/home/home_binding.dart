import 'package:demo_access_refresh_token_app/modules/home/home_controller.dart';
import 'package:get/get.dart';

class HomeBinding  extends Bindings{
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(()=> HomeController());
  }

}