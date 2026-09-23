class FacilityModel {
  final int? id;
  final String? name;
  final String? icon;
  final String? description;

  FacilityModel({this.id, this.name, this.icon, this.description});

  factory FacilityModel.fromJson(Map<String, dynamic> json) {
    return FacilityModel(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'description': description,
    };
  }
}
