class TenantModel {
  final int? id;
  final String? name;
  final String? roomNumber;
  final String? floor;
  final String? email;
  final String? phoneNumber;
  final String? status; // ACTIVE, PENDING, MOVED_OUT
  final String? joinedDate;

  TenantModel({
    this.id,
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
