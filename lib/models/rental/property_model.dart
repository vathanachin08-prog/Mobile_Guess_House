import 'room_model.dart';

class OwnerSummaryModel {
  final int? id;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? profile;

  OwnerSummaryModel({
    this.id,
    this.username,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.profile,
  });

  String get displayName {
    if (firstName != null && firstName!.isNotEmpty) {
      return "$firstName ${lastName ?? ''}".trim();
    }
    return username ?? "Owner";
  }

  factory OwnerSummaryModel.fromJson(Map<String, dynamic> json) {
    return OwnerSummaryModel(
      id: json['id'],
      username: json['username'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'],
      profile: json['profile'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'profile': profile,
    };
  }
}

class PropertyModel {
  final int? id;
  final String? name;
  final String? description;
  final String? propertyType; // APARTMENT, HOUSE, CONDO, DORMITORY, ROOM
  final String? address;
  final String? city;
  final String? district;
  final double? latitude;
  final double? longitude;
  final String? status; // DRAFT, PUBLISHED, UNPUBLISHED, SUSPENDED
  final String? verificationStatus; // PENDING, VERIFIED, REJECTED
  final String? mainImage;
  final String? images;
  final OwnerSummaryModel? owner;
  final List<RoomModel>? rooms;
  final double? minRoomPrice;
  final int? availableRoomCount;
  final int? totalRoomCount;
  final double? averageRating;
  final int? reviewCount;
  final String? createdAt;
  final String? updatedAt;

  PropertyModel({
    this.id,
    this.name,
    this.description,
    this.propertyType,
    this.address,
    this.city,
    this.district,
    this.latitude,
    this.longitude,
    this.status,
    this.verificationStatus,
    this.mainImage,
    this.images,
    this.owner,
    this.rooms,
    this.minRoomPrice,
    this.availableRoomCount,
    this.totalRoomCount,
    this.averageRating,
    this.reviewCount,
    this.createdAt,
    this.updatedAt,
  });

  bool get isVerified => verificationStatus == 'VERIFIED';
  bool get isPublished => status == 'PUBLISHED';

  String get fullLocation {
    final parts = [address, district, city].where((e) => e != null && e.isNotEmpty).toList();
    return parts.isEmpty ? "Phnom Penh" : parts.join(", ");
  }

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    List<RoomModel> roomList = [];
    if (json['rooms'] != null && json['rooms'] is List) {
      roomList = (json['rooms'] as List)
          .map((r) => RoomModel.fromJson(r is Map<String, dynamic> ? r : Map<String, dynamic>.from(r)))
          .toList();
    }

    return PropertyModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      propertyType: json['propertyType'],
      address: json['address'],
      city: json['city'],
      district: json['district'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      status: json['status'],
      verificationStatus: json['verificationStatus'],
      mainImage: json['mainImage'],
      images: json['images'],
      owner: json['owner'] != null ? OwnerSummaryModel.fromJson(
        json['owner'] is Map<String, dynamic> ? json['owner'] : Map<String, dynamic>.from(json['owner'])
      ) : null,
      rooms: roomList,
      minRoomPrice: json['minRoomPrice'] != null ? (json['minRoomPrice'] as num).toDouble() : null,
      availableRoomCount: json['availableRoomCount'],
      totalRoomCount: json['totalRoomCount'],
      averageRating: json['averageRating'] != null ? (json['averageRating'] as num).toDouble() : 4.5,
      reviewCount: json['reviewCount'] ?? 0,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'propertyType': propertyType,
      'address': address,
      'city': city,
      'district': district,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'verificationStatus': verificationStatus,
      'mainImage': mainImage,
      'images': images,
      'owner': owner?.toJson(),
      'rooms': rooms?.map((r) => r.toJson()).toList(),
      'minRoomPrice': minRoomPrice,
      'availableRoomCount': availableRoomCount,
      'totalRoomCount': totalRoomCount,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
