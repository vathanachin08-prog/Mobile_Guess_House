import 'package:get/get.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/employee_repository.dart';
import '../../repositories/product_repository.dart';
import '../employee/employee_controller.dart';
import '../product/product_controller.dart';
import 'portal_controller.dart';

class PortalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PortalController>(
      () => PortalController(authRepository: Get.find<AuthRepository>()),
    );
    Get.lazyPut<ProductListController>(
      () => ProductListController(repository: Get.find<ProductRepository>()),
    );
    Get.lazyPut<EmployeeController>(
      () => EmployeeController(repository: Get.find<EmployeeRepository>()),
    );
  }
}

