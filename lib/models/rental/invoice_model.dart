class InvoiceModel {
  final int? id;
  final String? invoiceNo;
  final String? propertyName;
  final String? tenantName;
  final String? roomNumber;
  final String? floor;
  final String? issueDate;
  final String? dueDate;
  final double? rentAmount;
  final double? electricityUnits;
  final double? electricityRate;
  final double? waterUnits;
  final double? waterRate;
  final double? garbageFee;
  final double? totalAmount;
  final String? status; // PAID, UNPAID, OVERDUE
  final String? khqrImageUrl;

  InvoiceModel({
    this.id,
    this.invoiceNo,
    this.propertyName,
    this.tenantName,
    this.roomNumber,
    this.floor,
    this.issueDate,
    this.dueDate,
    this.rentAmount,
    this.electricityUnits,
    this.electricityRate,
    this.waterUnits,
    this.waterRate,
    this.garbageFee,
    this.totalAmount,
    this.status = 'UNPAID',
    this.khqrImageUrl,
  });

  bool get isPaid => status == 'PAID';
  bool get isOverdue => status == 'OVERDUE';
  bool get isUnpaid => status == 'UNPAID';

  double get electricityTotal => (electricityUnits ?? 0) * (electricityRate ?? 0.12);
  double get waterTotal => (waterUnits ?? 0) * (waterRate ?? 1.5);

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'],
      invoiceNo: json['invoiceNo'],
      propertyName: json['propertyName'],
      tenantName: json['tenantName'],
      roomNumber: json['roomNumber'],
      floor: json['floor'],
      issueDate: json['issueDate'],
      dueDate: json['dueDate'],
      rentAmount: json['rentAmount'] != null ? (json['rentAmount'] as num).toDouble() : 50.0,
      electricityUnits: json['electricityUnits'] != null ? (json['electricityUnits'] as num).toDouble() : 1.0,
      electricityRate: json['electricityRate'] != null ? (json['electricityRate'] as num).toDouble() : 0.12,
      waterUnits: json['waterUnits'] != null ? (json['waterUnits'] as num).toDouble() : 1.0,
      waterRate: json['waterRate'] != null ? (json['waterRate'] as num).toDouble() : 1.5,
      garbageFee: json['garbageFee'] != null ? (json['garbageFee'] as num).toDouble() : 0.0,
      totalAmount: json['totalAmount'] != null ? (json['totalAmount'] as num).toDouble() : 51.62,
      status: json['status'] ?? 'UNPAID',
      khqrImageUrl: json['khqrImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNo': invoiceNo,
      'propertyName': propertyName,
      'tenantName': tenantName,
      'roomNumber': roomNumber,
      'floor': floor,
      'issueDate': issueDate,
      'dueDate': dueDate,
      'rentAmount': rentAmount,
      'electricityUnits': electricityUnits,
      'electricityRate': electricityRate,
      'waterUnits': waterUnits,
      'waterRate': waterRate,
      'garbageFee': garbageFee,
      'totalAmount': totalAmount,
      'status': status,
      'khqrImageUrl': khqrImageUrl,
    };
  }
}
