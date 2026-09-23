import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import 'dashboard/owner_dashboard_controller.dart';
import 'rooms/owner_rooms_controller.dart';

class OwnerMainController extends GetxController {
  final currentIndex = 0.obs;

  void changeTab(int index) {
    currentIndex.value = index;
  }
}

class OwnerMainBinding extends Bindings {
  @override
  void dependencies() {
    final api = Get.find<ApiService>();
    Get.lazyPut(() => OwnerMainController());
    Get.lazyPut(() => OwnerDashboardController(apiService: api));
    Get.lazyPut(() => OwnerRoomsController());
  }
}
