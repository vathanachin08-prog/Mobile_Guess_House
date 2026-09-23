import 'package:demo_access_refresh_token_app/modules/post/post_form_controller.dart';
import 'package:get/get.dart';

class PostFormBinding extends Bindings{
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(()=> PostFormController());
  }

}