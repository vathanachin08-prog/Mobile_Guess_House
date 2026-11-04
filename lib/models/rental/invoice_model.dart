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

  InvoiceModel copyWith({
    int? id,
    String? invoiceNo,
    String? propertyName,
    String? tenantName,
    String? roomNumber,
    String? floor,
    String? issueDate,
    String? dueDate,
    double? rentAmount,
    double? electricityUnits,
    double? electricityRate,
    double? waterUnits,
    double? waterRate,
    double? garbageFee,
    double? totalAmount,
    String? status,
    String? khqrImageUrl,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      propertyName: propertyName ?? this.propertyName,
      tenantName: tenantName ?? this.tenantName,
      roomNumber: roomNumber ?? this.roomNumber,
      floor: floor ?? this.floor,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      rentAmount: rentAmount ?? this.rentAmount,
      electricityUnits: electricityUnits ?? this.electricityUnits,
      electricityRate: electricityRate ?? this.electricityRate,
      waterUnits: waterUnits ?? this.waterUnits,
      waterRate: waterRate ?? this.waterRate,
      garbageFee: garbageFee ?? this.garbageFee,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      khqrImageUrl: khqrImageUrl ?? this.khqrImageUrl,
    );
  }

  bool get isPaid => status == 'PAID';
  bool get isOverdue => status == 'OVERDUE';
  bool get isUnpaid => status == 'UNPAID';

  double get electricityTotal => (electricityUnits ?? 0) * (electricityRate ?? 0.12);
  double get waterTotal => (waterUnits ?? 0) * (waterRate ?? 1.5);

  /// Returns parsed DateTime from issueDate, invoiceNo, or timestamp ID
  DateTime? get parsedIssueDate {
    if (issueDate != null && issueDate!.trim().isNotEmpty) {
      final str = issueDate!.trim();
      final direct = DateTime.tryParse(str);
      if (direct != null) return direct;

      // Normalize Khmer numerals to arabic
      final khmerDigits = {'១': '1', '២': '2', '៣': '3', '៤': '4', '៥': '5', '៦': '6', '៧': '7', '៨': '8', '៩': '9', '០': '0'};
      String norm = str;
      khmerDigits.forEach((k, v) => norm = norm.replaceAll(k, v));

      // English months: "Nov 2, 2026" or "2 Nov 2026"
      final engMonths = {
        'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
        'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
      };
      final lower = norm.toLowerCase();
      for (final entry in engMonths.entries) {
        if (lower.contains(entry.key)) {
          final nums = RegExp(r'\d+').allMatches(norm).map((m) => int.parse(m.group(0)!)).toList();
          if (nums.isNotEmpty) {
            final year = nums.firstWhere((n) => n >= 2000, orElse: () => DateTime.now().year);
            final day = nums.firstWhere((n) => n < 2000 && n <= 31, orElse: () => 1);
            return DateTime(year, entry.value, day);
          }
        }
      }

      // Khmer months: "2 វិច្ឆិកា 2026"
      final khmerMonths = {
        'មករា': 1, 'កុម្ភៈ': 2, 'មីនា': 3, 'មេសា': 4, 'ឧសភា': 5, 'មិថុនា': 6,
        'កក្កដា': 7, 'សីហា': 8, 'កញ្ញា': 9, 'តុលា': 10, 'វិច្ឆិកា': 11, 'ធ្នូ': 12,
      };
      for (final entry in khmerMonths.entries) {
        if (norm.contains(entry.key)) {
          final nums = RegExp(r'\d+').allMatches(norm).map((m) => int.parse(m.group(0)!)).toList();
          if (nums.isNotEmpty) {
            final year = nums.firstWhere((n) => n >= 2000, orElse: () => DateTime.now().year);
            final day = nums.firstWhere((n) => n < 2000 && n <= 31, orElse: () => 1);
            return DateTime(year, entry.value, day);
          }
        }
      }
    }

    // Extract year & month from invoiceNo: INV-YYYYMM-...
    if (invoiceNo != null) {
      final match = RegExp(r'INV-(\d{4})(\d{2})').firstMatch(invoiceNo!);
      if (match != null) {
        final y = int.tryParse(match.group(1) ?? '');
        final m = int.tryParse(match.group(2) ?? '');
        if (y != null && m != null) {
          return DateTime(y, m, 1);
        }
      }
    }

    // Fallback from timestamp in id
    if (id != null && id! > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(id!);
    }

    return null;
  }

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
