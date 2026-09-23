import 'package:get/get.dart';
import '../core/services/api_service.dart';
import '../core/services/api_service_impl.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApiService>(() => ApiServiceImpl(), fenix: true);
  }
}