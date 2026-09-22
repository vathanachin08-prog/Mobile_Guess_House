import 'dart:convert';

import 'package:demo_access_refresh_token_app/constants/constant_uri.dart';
import 'package:demo_access_refresh_token_app/core/services/api_service.dart';
import 'package:demo_access_refresh_token_app/data/local/token_store_local.dart';
import 'package:demo_access_refresh_token_app/models/login/LoginRequest.dart';
import 'package:demo_access_refresh_token_app/models/login/LoginResponse.dart';
import 'package:demo_access_refresh_token_app/models/login/RefreshTokenRequest.dart';
import 'package:demo_access_refresh_token_app/routes/app_route_name.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as httpClient;

class ApiServiceImpl implements ApiService {
  var headers = {"Content-Type": "application/json"};
  @override
  Future<LoginResponse> login({LoginRequest? body}) async {
    var url = Uri.parse(ConstantUri.login);
    var response = await httpClient.post(
      url,
      body: jsonEncode(body!.toJson()),
      headers: headers,
    );
    if (response.statusCode == 200) {
      var loginResponse = LoginResponse.fromJson(jsonDecode(response.body));
      return loginResponse;
    }
    return LoginResponse();
  }

  @override
  Future<bool> refreshToken(String token) async {
    var url = Uri.parse(ConstantUri.refreshToken);
    var refreshTokenBody = RefreshTokenRequest(refreshToken: token);
    var response = await httpClient.post(
      url,
      body: jsonEncode(refreshTokenBody.toJson()),
      headers: headers,
    );
    if (response.statusCode == 200) {
      var loginResponse = LoginResponse.fromJson(jsonDecode(response.body));
      TokenStoreLocal.setRefreshToken(loginResponse.refreshToken ?? "");
      TokenStoreLocal.setAccessToken(loginResponse.accessToken ?? "");
      return true;
    }
    return false;
  }

  @override
  Future<dynamic> getApi(String url, {String? param}) async {
    var response = await httpClient.get(
      Uri.parse(url),
      headers: {"Authorization": "Bearer ${TokenStoreLocal.getAccessToken()}"},
    );
    if (response.statusCode == 200) {
      return response.body;
    } else if (response.statusCode == 401) {
      var refreshResponse = await refreshToken(
        TokenStoreLocal.getRefreshToken(),
      );
      if (refreshResponse == false) {
        TokenStoreLocal.removeToken();
        Get.offNamed(AppRouteName.login);
        return;
      } else {
        return await getApiRetry(url, param: param);
      }
    }
    return null;
  }

  dynamic getApiRetry(String url, {String? param}) async {
    var response = await httpClient.get(
      Uri.parse(url),
      headers: {"Authorization": "Bearer ${TokenStoreLocal.getAccessToken()}"},
    );
    return response.body;
  }
}
