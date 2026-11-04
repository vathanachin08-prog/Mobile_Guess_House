class EmployeeModel {
  final dynamic id;
  final String name;
  final String email;
  final String phone;
  final String position;
  final String department;
  final double salary;
  final String status;
  final String? profileImage;
  final String? createdAt;
  final String? updatedAt;

  EmployeeModel({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.position,
    required this.department,
    required this.salary,
    this.status = 'ACT',
    this.profileImage,
    this.createdAt,
    this.updatedAt,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'],
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      position: json['position']?.toString() ?? '',
      department: json['department']?.toString() ?? 'General',
      salary: json['salary'] is num
          ? (json['salary'] as num).toDouble()
          : double.tryParse(json['salary']?.toString() ?? '0.0') ?? 0.0,
      status: json['status']?.toString() ?? 'ACT',
      profileImage: json['profileImage']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'position': position,
      'department': department,
      'salary': salary,
      'status': status,
      if (profileImage != null) 'profileImage': profileImage,
    };
  }

  EmployeeModel copyWith({
    dynamic id,
    String? name,
    String? email,
    String? phone,
    String? position,
    String? department,
    double? salary,
    String? status,
    String? profileImage,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      position: position ?? this.position,
      department: department ?? this.department,
      salary: salary ?? this.salary,
      status: status ?? this.status,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String get initials {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[parts.length - 1].substring(0, 1)).toUpperCase();
  }

  String get formattedSalary {
    return '\$${salary.toStringAsFixed(2)}';
  }

  bool get isActive => status.toUpperCase() == 'ACT' || status.toUpperCase() == 'ACTIVE';
}

