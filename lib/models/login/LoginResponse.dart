import 'User.dart';

class LoginResponse {
  LoginResponse({
      this.accessToken, 
      this.tokenType, 
      this.refreshToken, 
      this.expiresIn, 
      this.user,});

  LoginResponse.fromJson(dynamic json) {
    accessToken = json['accessToken'];
    tokenType = json['tokenType'];
    refreshToken = json['refreshToken'];
    expiresIn = json['expiresIn'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }
  String? accessToken;
  String? tokenType;
  String? refreshToken;
  int? expiresIn;
  User? user;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['accessToken'] = accessToken;
    map['tokenType'] = tokenType;
    map['refreshToken'] = refreshToken;
    map['expiresIn'] = expiresIn;
    if (user != null) {
      map['user'] = user?.toJson();
    }
    return map;
  }

}