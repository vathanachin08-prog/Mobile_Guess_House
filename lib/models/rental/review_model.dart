class ReviewModel {
  final int? id;
  final int? studentId;
  final String? studentName;
  final int? propertyId;
  final int? rating;
  final String? comment;
  final String? createdAt;
  final String? updatedAt;

  ReviewModel({
    this.id,
    this.studentId,
    this.studentName,
    this.propertyId,
    this.rating,
    this.comment,
    this.createdAt,
    this.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'],
      studentId: json['studentId'],
      studentName: json['studentName'] ?? json['studentUsername'] ?? "Student",
      propertyId: json['propertyId'],
      rating: json['rating'] ?? 5,
      comment: json['comment'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'propertyId': propertyId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
