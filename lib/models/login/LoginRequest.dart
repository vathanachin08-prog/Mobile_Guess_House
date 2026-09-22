class LoginRequest {
  LoginRequest({
      this.phoneNumber, 
      this.password,});

  LoginRequest.fromJson(dynamic json) {
    phoneNumber = json['phoneNumber'];
    password = json['password'];
  }
  String? phoneNumber;
  String? password;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['phoneNumber'] = phoneNumber;
    map['password'] = password;
    return map;
  }

}