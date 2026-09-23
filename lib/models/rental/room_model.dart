import 'facility_model.dart';

class RoomModel {
  final int? id;
  final int? propertyId;
  final String? propertyName;
  final String? roomNumber;
  final String? title;
  final String? description;
  final double? price;
  final String? roomType; // SINGLE, DOUBLE, SHARED
  final String? genderPreference; // MALE, FEMALE, ANY
  final bool? available;
  final int? floor;
  final double? area;
  final String? images;
  final List<FacilityModel>? facilities;
  final String? createdAt;
  final String? updatedAt;

  RoomModel({
    this.id,
    this.propertyId,
    this.propertyName,
    this.roomNumber,
    this.title,
    this.description,
    this.price,
    this.roomType,
    this.genderPreference,
    this.available,
    this.floor,
    this.area,
    this.images,
    this.facilities,
    this.createdAt,
    this.updatedAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    List<FacilityModel> facs = [];
    if (json['facilities'] != null) {
      if (json['facilities'] is List) {
        facs = (json['facilities'] as List)
            .map((f) => FacilityModel.fromJson(f is Map<String, dynamic> ? f : Map<String, dynamic>.from(f)))
            .toList();
      }
    }

    return RoomModel(
      id: json['id'],
      propertyId: json['propertyId'],
      propertyName: json['propertyName'],
      roomNumber: json['roomNumber'],
      title: json['title'],
      description: json['description'],
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      roomType: json['roomType'],
      genderPreference: json['genderPreference'],
      available: json['available'] == true,
      floor: json['floor'],
      area: json['area'] != null ? (json['area'] as num).toDouble() : null,
      images: json['images'],
      facilities: facs,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'propertyName': propertyName,
      'roomNumber': roomNumber,
      'title': title,
      'description': description,
      'price': price,
      'roomType': roomType,
      'genderPreference': genderPreference,
      'available': available,
      'floor': floor,
      'area': area,
      'images': images,
      'facilities': facilities?.map((f) => f.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
