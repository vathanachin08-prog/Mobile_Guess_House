import 'Content.dart';

class Data {
  Data({
      this.content, 
      this.page, 
      this.size, 
      this.totalElements, 
      this.totalPages, 
      this.last,});

  Data.fromJson(dynamic json) {
    if (json['content'] != null) {
      content = [];
      json['content'].forEach((v) {
        content?.add(Content.fromJson(v));
      });
    }
    page = json['page'];
    size = json['size'];
    totalElements = json['totalElements'];
    totalPages = json['totalPages'];
    last = json['last'];
  }
  List<Content>? content;
  int? page;
  int? size;
  int? totalElements;
  int? totalPages;
  bool? last;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (content != null) {
      map['content'] = content?.map((v) => v.toJson()).toList();
    }
    map['page'] = page;
    map['size'] = size;
    map['totalElements'] = totalElements;
    map['totalPages'] = totalPages;
    map['last'] = last;
    return map;
  }

}