import 'Data.dart';

class PostResponse {
  PostResponse({
      this.code, 
      this.message, 
      this.messageKh, 
      this.data,});

  PostResponse.fromJson(dynamic json) {
    code = json['code'];
    message = json['message'];
    messageKh = json['messageKh'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }
  String? code;
  String? message;
  String? messageKh;
  Data? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['code'] = code;
    map['message'] = message;
    map['messageKh'] = messageKh;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}