import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import 'dashboard/owner_dashboard_controller.dart';
import 'floors/owner_floors_controller.dart';
import 'rooms/owner_rooms_controller.dart';
import 'profile/owner_profile_controller.dart';

class OwnerMainController extends GetxController {
  final currentIndex = 0.obs;

  void changeTab(int index) {
    currentIndex.value = index;
    if (index == 3 && Get.isRegistered<OwnerProfileController>()) {
      final ctrl = Get.find<OwnerProfileController>();
      ctrl.loadUser();
      ctrl.fetchProfileFromServer();
    }
  }
}

class OwnerMainBinding extends Bindings {
  @override
  void dependencies() {
    final api = Get.find<ApiService>();
    Get.lazyPut(() => OwnerMainController());
    Get.lazyPut(() => OwnerDashboardController(apiService: api));
    Get.lazyPut(() => OwnerFloorsController(apiService: api));
    Get.lazyPut(() => OwnerRoomsController(apiService: api));
    Get.lazyPut(() => OwnerProfileController());
  }
}
