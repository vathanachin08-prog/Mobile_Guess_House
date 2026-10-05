import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import 'owner_visit_requests_controller.dart';

class OwnerVisitRequestsBinding extends Bindings {
  @override
  void dependencies() {
    final api = Get.isRegistered<ApiService>() ? Get.find<ApiService>() : null;
    if (api != null) {
      Get.lazyPut(() => OwnerVisitRequestsController(apiService: api));
    }
  }
}
