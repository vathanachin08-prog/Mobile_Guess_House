class VisitRequestModel {
  final int? id;
  final int? studentId;
  final String? studentName;
  final String? studentPhone;
  final int? propertyId;
  final String? propertyName;
  final int? roomId;
  final String? roomNumber;
  final String? requestedDate;
  final String? requestedTime;
  final String? message;
  final String? status; // PENDING, ACCEPTED, REJECTED, CANCELLED, COMPLETED
  final String? createdAt;
  final String? updatedAt;

  VisitRequestModel({
    this.id,
    this.studentId,
    this.studentName,
    this.studentPhone,
    this.propertyId,
    this.propertyName,
    this.roomId,
    this.roomNumber,
    this.requestedDate,
    this.requestedTime,
    this.message,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory VisitRequestModel.fromJson(Map<String, dynamic> json) {
    return VisitRequestModel(
      id: json['id'],
      studentId: json['studentId'],
      studentName: json['studentName'],
      studentPhone: json['studentPhone'],
      propertyId: json['propertyId'],
      propertyName: json['propertyName'],
      roomId: json['roomId'],
      roomNumber: json['roomNumber'],
      requestedDate: json['requestedDate'],
      requestedTime: json['requestedTime'],
      message: json['message'] ?? json['notes'],
      status: json['status'] ?? 'PENDING',
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'studentPhone': studentPhone,
      'propertyId': propertyId,
      'propertyName': propertyName,
      'roomId': roomId,
      'roomNumber': roomNumber,
      'requestedDate': requestedDate,
      'requestedTime': requestedTime,
      'message': message,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
