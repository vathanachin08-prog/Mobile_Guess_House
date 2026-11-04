class ProductModel {
  final int? id;
  final String? name;
  final String? productCode;
  final String? categoryName;
  final double? price;
  final double? cost;
  final double? stockQuantity;
  final String? description;
  final String? status;

  ProductModel({
    this.id,
    this.name,
    this.productCode,
    this.categoryName,
    this.price,
    this.cost,
    this.stockQuantity,
    this.description,
    this.status,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    String? catName;
    if (json['category'] != null) {
      if (json['category'] is Map) {
        catName = json['category']['name']?.toString();
      } else {
        catName = json['category'].toString();
      }
    } else if (json['categoryName'] != null) {
      catName = json['categoryName'].toString();
    }

    return ProductModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : int.tryParse(json['id']?.toString() ?? ''),
      name: json['name']?.toString() ?? '',
      productCode: json['productCode']?.toString() ?? json['code']?.toString() ?? '',
      categoryName: catName ?? 'General',
      price: json['price'] is num ? (json['price'] as num).toDouble() : double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      cost: json['cost'] is num ? (json['cost'] as num).toDouble() : double.tryParse(json['cost']?.toString() ?? '0.0') ?? 0.0,
      stockQuantity: json['stockQuantity'] is num ? (json['stockQuantity'] as num).toDouble() : double.tryParse(json['stockQuantity']?.toString() ?? '0.0') ?? 0.0,
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACT',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'productCode': productCode,
      'price': price,
      'cost': cost,
      'stockQuantity': stockQuantity,
      'description': description,
      'status': status,
    };
  }
}

