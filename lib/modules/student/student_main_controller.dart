import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import 'home/student_home_controller.dart';
import 'search/student_search_controller.dart';
import 'favorites/favorites_controller.dart';
import 'visit_requests/visit_requests_controller.dart';
import 'profile/student_profile_controller.dart';

class StudentMainController extends GetxController {
  final currentIndex = 0.obs;

  void changeTab(int index) {
    currentIndex.value = index;
    if (index == 2 && Get.isRegistered<FavoritesController>()) {
      Get.find<FavoritesController>().loadFavorites();
    }
    if (index == 3 && Get.isRegistered<VisitRequestsController>()) {
      Get.find<VisitRequestsController>().loadRequests();
    }
    if (index == 4 && Get.isRegistered<StudentProfileController>()) {
      final ctrl = Get.find<StudentProfileController>();
      ctrl.loadUser();
      ctrl.fetchProfileFromServer();
    }
  }
}

class StudentMainBinding extends Bindings {
  @override
  void dependencies() {
    final api = Get.find<ApiService>();
    Get.lazyPut(() => StudentMainController());
    Get.lazyPut(() => StudentHomeController(apiService: api));
    Get.lazyPut(() => StudentSearchController(apiService: api));
    Get.lazyPut(() => FavoritesController(apiService: api));
    Get.lazyPut(() => VisitRequestsController(apiService: api));
    Get.lazyPut(() => StudentProfileController());
  }
}
