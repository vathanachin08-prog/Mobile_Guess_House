import 'package:get/get.dart';
import '../../repositories/employee_repository.dart';
import 'employee_controller.dart';

class EmployeeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EmployeeController>(
      () => EmployeeController(repository: Get.find<EmployeeRepository>()),
    );
  }
}

