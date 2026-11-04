import 'dart:convert';
import '../constants/constant_uri.dart';
import '../core/services/api_service.dart';
import '../models/product/product_model.dart';

abstract class ProductRepository {
  Future<List<ProductModel>> getProducts({String? status});
  Future<List<String>> getCategories();
  Future<ProductModel?> getProductById(dynamic id);
}

class ProductRepositoryImpl implements ProductRepository {
  final ApiService apiService;

  ProductRepositoryImpl({required this.apiService});

  @override
  Future<List<ProductModel>> getProducts({String? status}) async {
    // Try GET first
    dynamic response = await apiService.getApi(ConstantUri.products);
    // Fallback to POST if needed
    if (response == null) {
      response = await apiService.postApi(
        ConstantUri.products,
        body: {"status": status ?? "ACT"},
      );
    }

    if (response == null) {
      throw Exception("Unable to load products from ${ConstantUri.baseUri}. Please check server connectivity.");
    }

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
      } else if (decoded['message'] != null && decoded['code'] != 'SUC-000' && decoded['code'] != '200') {
        throw Exception(decoded['message'].toString());
      }
    }

    if (rawList != null) {
      return rawList.map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item))).toList();
    }

    return [];
  }

  @override
  Future<List<String>> getCategories() async {
    try {
      dynamic response = await apiService.getApi(ConstantUri.productCategories);
      if (response == null) {
        response = await apiService.postApi(ConstantUri.productCategories, body: {});
      }
      if (response != null) {
        final decoded = response is String ? jsonDecode(response) : response;
        List<dynamic>? list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          list = decoded['data'];
        }
        if (list != null) {
          final cats = list
              .map((c) => (c is Map ? c['name']?.toString() : c.toString()) ?? '')
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList();
          return cats;
        }
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<ProductModel?> getProductById(dynamic id) async {
    final response = await apiService.getApi(ConstantUri.productDetail(id));
    if (response != null) {
      final decoded = response is String ? jsonDecode(response) : response;
      if (decoded is Map<String, dynamic>) {
        final data = decoded['data'] ?? decoded;
        return ProductModel.fromJson(Map<String, dynamic>.from(data));
      }
    }
    return null;
  }
}
