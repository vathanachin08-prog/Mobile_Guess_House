class TenantModel {
  final int? id;
  final int? propertyId;
  final String? name;
  final String? roomNumber;
  final String? floor;
  final String? email;
  final String? phoneNumber;
  final String? status; // ACTIVE, PENDING, MOVED_OUT
  final String? joinedDate;

  TenantModel({
    this.id,
    this.propertyId,
    this.name,
    this.roomNumber,
    this.floor,
    this.email,
    this.phoneNumber,
    this.status = 'ACTIVE',
    this.joinedDate,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: json['id'],
      propertyId: json['propertyId'] != null ? (json['propertyId'] as num).toInt() : null,
      name: json['name'],
      roomNumber: json['roomNumber'],
      floor: json['floor'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      status: json['status'] ?? 'ACTIVE',
      joinedDate: json['joinedDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'name': name,
      'roomNumber': roomNumber,
      'floor': floor,
      'email': email,
      'phoneNumber': phoneNumber,
      'status': status,
      'joinedDate': joinedDate,
    };
  }
}
