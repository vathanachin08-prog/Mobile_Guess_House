import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/product/product_model.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/app_colors.dart';

class ProductListController extends GetxController {
  final ProductRepository repository;

  ProductListController({required this.repository});

  final products = <ProductModel>[].obs;
  final filteredProducts = <ProductModel>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final selectedCategory = 'All'.obs;
  final categories = <String>['All', 'Electronics', 'Accessories', 'Office'].obs;
  final errorMessage = ''.obs;

  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchProducts() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final list = await repository.getProducts();
      products.assignAll(list);

      // Extract unique categories dynamically
      final catSet = <String>{'All'};
      for (final p in list) {
        if (p.categoryName != null && p.categoryName!.isNotEmpty) {
          catSet.add(p.categoryName!);
        }
      }
      categories.assignAll(catSet.toList());

      applyFilter();
    } catch (e) {
      errorMessage.value = 'Failed to load products: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    applyFilter();
  }

  void onCategorySelected(String cat) {
    selectedCategory.value = cat;
    applyFilter();
  }

  void applyFilter() {
    final query = searchQuery.value.trim().toLowerCase();
    final cat = selectedCategory.value;

    filteredProducts.assignAll(
      products.where((prod) {
        final matchesSearch = query.isEmpty ||
            (prod.name ?? '').toLowerCase().contains(query) ||
            (prod.productCode ?? '').toLowerCase().contains(query) ||
            (prod.description ?? '').toLowerCase().contains(query);

        final matchesCat = cat == 'All' ||
            (prod.categoryName ?? '').toLowerCase() == cat.toLowerCase();

        return matchesSearch && matchesCat;
      }).toList(),
    );
  }

  void showProductDetails(ProductModel product) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name ?? 'Product Details',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Code: ${product.productCode ?? 'N/A'}',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.categoryName ?? 'General',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),
              // Pricing & Stock Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      'Price',
                      '\$${(product.price ?? 0.0).toStringAsFixed(2)}',
                      Colors.green.shade700,
                      Colors.green.shade50,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      'Stock',
                      '${(product.stockQuantity ?? 0.0).toStringAsFixed(0)} units',
                      Colors.blue.shade700,
                      Colors.blue.shade50,
                    ),
                  ),
                  if (product.cost != null && product.cost! > 0) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricTile(
                        'Cost',
                        '\$${(product.cost ?? 0.0).toStringAsFixed(2)}',
                        Colors.orange.shade800,
                        Colors.orange.shade50,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Description',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                (product.description != null && product.description!.isNotEmpty)
                    ? product.description!
                    : 'No detailed description available for this product item.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildMetricTile(String label, String value, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.8), fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }
}

