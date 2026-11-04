import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../constants/constant_uri.dart';
import '../core/services/api_service.dart';
import '../models/product/product_model.dart';

abstract class ProductRepository {
  Future<List<ProductModel>> getProducts({String? status});
  Future<ProductModel?> getProductById(dynamic id);
}

class ProductRepositoryImpl implements ProductRepository {
  final ApiService apiService;

  ProductRepositoryImpl({required this.apiService});

  @override
  Future<List<ProductModel>> getProducts({String? status}) async {
    try {
      // Try GET first
      dynamic response = await apiService.getApi(ConstantUri.products);
      // Fallback to POST if server prefers POST for /list
      if (response == null) {
        response = await apiService.postApi(
          ConstantUri.products,
          body: {"status": status ?? "ACT"},
        );
      }

      if (response != null) {
        final decoded = response is String ? jsonDecode(response) : response;
        List<dynamic>? rawList;

        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is List) {
            rawList = decoded['data'];
          } else if (decoded['data'] is Map && decoded['data']['content'] is List) {
            rawList = decoded['data']['content'];
          } else if (decoded['content'] is List) {
            rawList = decoded['content'];
          }
        }

        if (rawList != null && rawList.isNotEmpty) {
          return rawList.map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item))).toList();
        }
      }
    } catch (e) {
      debugPrint("ProductRepository getProducts error: $e");
    }

    // Default fallback demo products if empty
    return _getFallbackProducts();
  }

  @override
  Future<ProductModel?> getProductById(dynamic id) async {
    try {
      final response = await apiService.getApi(ConstantUri.productDetail(id));
      if (response != null) {
        final decoded = response is String ? jsonDecode(response) : response;
        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'] ?? decoded;
          return ProductModel.fromJson(Map<String, dynamic>.from(data));
        }
      }
    } catch (e) {
      debugPrint("ProductRepository getProductById error: $e");
    }
    return null;
  }

  List<ProductModel> _getFallbackProducts() {
    return [
      ProductModel(
        id: 1,
        name: 'MacBook Pro 16" M3',
        productCode: 'PROD-MBP16-01',
        categoryName: 'Electronics',
        price: 2499.00,
        cost: 1999.00,
        stockQuantity: 25.0,
        description: 'Apple M3 Pro chip, 18GB unified memory, 512GB SSD storage',
        status: 'ACT',
      ),
      ProductModel(
        id: 2,
        name: 'Dell XPS 15 OLED',
        productCode: 'PROD-XPS15-02',
        categoryName: 'Electronics',
        price: 1899.00,
        cost: 1450.00,
        stockQuantity: 18.0,
        description: 'Intel Core i9, 32GB RAM, 1TB SSD, 3.5K OLED touchscreen display',
        status: 'ACT',
      ),
      ProductModel(
        id: 3,
        name: 'iPhone 16 Pro Max 256GB',
        productCode: 'PROD-IP16P-03',
        categoryName: 'Electronics',
        price: 1199.00,
        cost: 950.00,
        stockQuantity: 40.0,
        description: 'Titanium design, A18 Pro chip, 48MP fusion camera system',
        status: 'ACT',
      ),
      ProductModel(
        id: 4,
        name: 'Logitech MX Master 3S',
        productCode: 'PROD-MXM3S-04',
        categoryName: 'Accessories',
        price: 99.00,
        cost: 65.00,
        stockQuantity: 80.0,
        description: 'Performance wireless ergonomic mouse with 8K DPI tracking',
        status: 'ACT',
      ),
      ProductModel(
        id: 5,
        name: 'Sony WH-1000XM5 Wireless Headphones',
        productCode: 'PROD-WHXM5-05',
        categoryName: 'Accessories',
        price: 399.00,
        cost: 280.00,
        stockQuantity: 30.0,
        description: 'Industry-leading noise cancelling with Auto NC Optimizer',
        status: 'ACT',
      ),
      ProductModel(
        id: 6,
        name: 'Keychron Q1 Pro Mechanical Keyboard',
        productCode: 'PROD-KQ1P-06',
        categoryName: 'Accessories',
        price: 199.00,
        cost: 130.00,
        stockQuantity: 45.0,
        description: 'Custom wireless mechanical keyboard with CNC aluminum body',
        status: 'ACT',
      ),
    ];
  }
}

