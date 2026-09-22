import 'package:demo_access_refresh_token_app/models/login/LoginRequest.dart';
import 'package:demo_access_refresh_token_app/models/login/LoginResponse.dart';

abstract class ApiService {
  Future<LoginResponse> login({LoginRequest? body});
  Future<bool> refreshToken(String token);
  Future<dynamic> getApi(String url,{String? param});
}