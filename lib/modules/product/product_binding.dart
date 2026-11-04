import 'package:get/get.dart';
import '../../repositories/product_repository.dart';
import 'product_controller.dart';

class ProductBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProductListController>(
      () => ProductListController(repository: Get.find<ProductRepository>()),
    );
  }
}

