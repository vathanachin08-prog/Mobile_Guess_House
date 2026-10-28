import 'dart:convert';
import '../../core/services/language_service.dart';
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

  RoomModel copyWith({
    int? id,
    int? propertyId,
    String? propertyName,
    String? roomNumber,
    String? title,
    String? description,
    double? price,
    String? roomType,
    String? genderPreference,
    bool? available,
    int? floor,
    double? area,
    String? images,
    List<FacilityModel>? facilities,
    String? createdAt,
    String? updatedAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      roomNumber: roomNumber ?? this.roomNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      roomType: roomType ?? this.roomType,
      genderPreference: genderPreference ?? this.genderPreference,
      available: available ?? this.available,
      floor: floor ?? this.floor,
      area: area ?? this.area,
      images: images ?? this.images,
      facilities: facilities ?? this.facilities,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  List<String> get imageList {
    if (images == null || images!.trim().isEmpty) return [];
    final str = images!.trim();
    if (str.startsWith('[') && str.endsWith(']')) {
      try {
        final decoded = jsonDecode(str);
        if (decoded is List) {
          return decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        }
      } catch (_) {}
    }
    if (str.contains(',') && !str.startsWith('data:image')) {
      return str.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    return [str];
  }

  String? get firstImage {
    final list = imageList;
    return list.isNotEmpty ? list.first : null;
  }

  String get floorDisplayName {
    final isKhmer = LanguageService.isKhmer;
    if (floor == null || floor == 0 || floor == 1) {
      return isKhmer ? "ជាន់ផ្ទាល់ដី" : "Ground Floor";
    }
    final fNum = floor! > 1 ? floor! - 1 : floor!;
    final khmerDigits = {'1': '១', '2': '២', '3': '៣', '4': '៤', '5': '៥', '6': '៦', '7': '៧', '8': '៨', '9': '៩', '0': '០'};
    String khmerNum = fNum.toString();
    khmerDigits.forEach((k, v) => khmerNum = khmerNum.replaceAll(k, v));
    return isKhmer ? "ជាន់ទី $khmerNum" : "Floor $fNum";
  }

  String get roomTypeDisplayName {
    final type = (roomType ?? 'SINGLE').toUpperCase();
    if (LanguageService.isKhmer) {
      switch (type) {
        case 'SINGLE':
          return 'បន្ទប់ទោល';
        case 'DOUBLE':
          return 'បន្ទប់គូ';
        case 'SHARED':
          return 'បន្ទប់រួម';
        default:
          return type;
      }
    }
    switch (type) {
      case 'SINGLE':
        return 'Single';
      case 'DOUBLE':
        return 'Double';
      case 'SHARED':
        return 'Shared';
      default:
        return type;
    }
  }

  String get genderPreferenceDisplayName {
    final pref = (genderPreference ?? 'ANY').toUpperCase();
    if (LanguageService.isKhmer) {
      switch (pref) {
        case 'MALE':
          return 'បុរស';
        case 'FEMALE':
          return 'ស្ត្រី';
        case 'ANY':
          return 'ទូទៅ';
        default:
          return pref;
      }
    }
    switch (pref) {
      case 'MALE':
        return 'Male';
      case 'FEMALE':
        return 'Female';
      case 'ANY':
        return 'Any';
      default:
        return pref;
    }
  }

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    List<FacilityModel> facs = [];
    if (json['facilities'] != null) {
      if (json['facilities'] is List) {
        facs = (json['facilities'] as List)
            .map((f) => FacilityModel.fromJson(f is Map<String, dynamic> ? f : Map<String, dynamic>.from(f)))
            .toList();
      }
    }

    String? imagesStr;
    if (json['images'] != null) {
      if (json['images'] is List) {
        imagesStr = jsonEncode(json['images']);
      } else {
        imagesStr = json['images'].toString();
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
      images: imagesStr,
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
