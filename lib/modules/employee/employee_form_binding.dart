import 'package:get/get.dart';
import '../../repositories/employee_repository.dart';
import 'employee_form_controller.dart';

class EmployeeFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EmployeeFormController>(
      () => EmployeeFormController(repository: Get.find<EmployeeRepository>()),
    );
  }
}

