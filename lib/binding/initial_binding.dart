import 'package:get/get.dart';
import '../core/services/api_service.dart';
import '../core/services/api_service_impl.dart';
import '../core/services/chat_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ApiService>()) {
      Get.put<ApiService>(ApiServiceImpl(), permanent: true);
    }
    if (!Get.isRegistered<ChatService>()) {
      Get.put<ChatService>(ChatService(), permanent: true);
    }
  }
}