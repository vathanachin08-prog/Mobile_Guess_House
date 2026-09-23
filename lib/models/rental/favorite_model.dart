import 'property_model.dart';
import 'room_model.dart';

class FavoriteModel {
  final int? id;
  final int? studentId;
  final PropertyModel? property;
  final RoomModel? room;
  final String? createdAt;

  FavoriteModel({
    this.id,
    this.studentId,
    this.property,
    this.room,
    this.createdAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'],
      studentId: json['studentId'],
      property: json['property'] != null
          ? PropertyModel.fromJson(json['property'] is Map<String, dynamic>
              ? json['property']
              : Map<String, dynamic>.from(json['property']))
          : null,
      room: json['room'] != null
          ? RoomModel.fromJson(json['room'] is Map<String, dynamic>
              ? json['room']
              : Map<String, dynamic>.from(json['room']))
          : null,
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'property': property?.toJson(),
      'room': room?.toJson(),
      'createdAt': createdAt,
    };
  }
}
