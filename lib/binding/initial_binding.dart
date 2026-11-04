import 'package:get/get.dart';
import '../core/services/api_service.dart';
import '../core/services/api_service_impl.dart';
import '../core/services/chat_service.dart';
import '../repositories/auth_repository.dart';
import '../repositories/employee_repository.dart';
import '../repositories/product_repository.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ApiService>()) {
      Get.put<ApiService>(ApiServiceImpl(), permanent: true);
    }
    if (!Get.isRegistered<AuthRepository>()) {
      Get.put<AuthRepository>(AuthRepositoryImpl(apiService: Get.find<ApiService>()), permanent: true);
    }
    if (!Get.isRegistered<ProductRepository>()) {
      Get.put<ProductRepository>(ProductRepositoryImpl(apiService: Get.find<ApiService>()), permanent: true);
    }
    if (!Get.isRegistered<EmployeeRepository>()) {
      Get.put<EmployeeRepository>(EmployeeRepositoryImpl(apiService: Get.find<ApiService>()), permanent: true);
    }
    if (!Get.isRegistered<ChatService>()) {
      Get.put<ChatService>(ChatService(), permanent: true);
    }
  }
}
