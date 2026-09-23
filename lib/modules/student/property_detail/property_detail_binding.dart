import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import 'property_detail_controller.dart';

class PropertyDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PropertyDetailController(apiService: Get.find<ApiService>()));
  }
}
