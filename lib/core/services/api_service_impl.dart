import 'dart:convert';

import 'package:demo_access_refresh_token_app/constants/constant_uri.dart';
import 'package:demo_access_refresh_token_app/core/services/api_service.dart';
import 'package:demo_access_refresh_token_app/data/local/token_store_local.dart';
import 'package:demo_access_refresh_token_app/models/login/LoginRequest.dart';
import 'package:demo_access_refresh_token_app/models/login/LoginResponse.dart';
import 'package:demo_access_refresh_token_app/models/login/RefreshTokenRequest.dart';
import 'package:demo_access_refresh_token_app/routes/app_route_name.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ApiServiceImpl implements ApiService {
  Map<String, String> get jsonHeaders => {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };

  Map<String, String> get authHeaders {
    final token = TokenStoreLocal.getAccessToken();
    final h = <String, String>{
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
    if (token.isNotEmpty) {
      h["Authorization"] = "Bearer $token";
    }
    return h;
  }

  @override
  Future<LoginResponse> login({LoginRequest? body}) async {
    final url = Uri.parse(ConstantUri.login);
    final response = await http.post(
      url,
      body: jsonEncode(body!.toJson()),
      headers: jsonHeaders,
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final loginResponse = LoginResponse.fromJson(decoded);
      if (loginResponse.user != null) {
        TokenStoreLocal.setUser(loginResponse.user!.toJson());
      }
      return loginResponse;
    }
    return LoginResponse();
  }

  @override
  Future<dynamic> register({Map<String, dynamic>? body}) async {
    final url = Uri.parse(ConstantUri.register);
    final response = await http.post(
      url,
      body: jsonEncode(body ?? {}),
      headers: jsonHeaders,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    return null;
  }

  @override
  Future<bool> refreshToken(String token) async {
    final url = Uri.parse(ConstantUri.refreshToken);
    final refreshTokenBody = RefreshTokenRequest(refreshToken: token);
    final response = await http.post(
      url,
      body: jsonEncode(refreshTokenBody.toJson()),
      headers: jsonHeaders,
    );
    if (response.statusCode == 200) {
      final loginResponse = LoginResponse.fromJson(jsonDecode(response.body));
      TokenStoreLocal.setRefreshToken(loginResponse.refreshToken ?? "");
      TokenStoreLocal.setAccessToken(loginResponse.accessToken ?? "");
      return true;
    }
    return false;
  }

  @override
  Future<dynamic> getApi(String url, {String? param}) async {
    final fullUrl = param != null ? "$url?$param" : url;
    final response = await http.get(Uri.parse(fullUrl), headers: authHeaders);
    if (response.statusCode == 200) {
      return response.body;
    } else if (response.statusCode == 401) {
      final refreshed = await refreshToken(TokenStoreLocal.getRefreshToken());
      if (!refreshed) {
        TokenStoreLocal.removeToken();
        Get.offAllNamed(AppRouteName.login);
        return null;
      } else {
        final retryRes = await http.get(Uri.parse(fullUrl), headers: authHeaders);
        return retryRes.statusCode == 200 ? retryRes.body : null;
      }
    }
    return null;
  }

  @override
  Future<dynamic> postApi(String url, {dynamic body}) async {
    final encoded = body is String ? body : jsonEncode(body ?? {});
    final response = await http.post(Uri.parse(url), body: encoded, headers: authHeaders);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.body;
    } else if (response.statusCode == 401) {
      final refreshed = await refreshToken(TokenStoreLocal.getRefreshToken());
      if (!refreshed) {
        TokenStoreLocal.removeToken();
        Get.offAllNamed(AppRouteName.login);
        return null;
      } else {
        final retryRes = await http.post(Uri.parse(url), body: encoded, headers: authHeaders);
        return (retryRes.statusCode == 200 || retryRes.statusCode == 201) ? retryRes.body : null;
      }
    }
    return null;
  }

  @override
  Future<dynamic> putApi(String url, {dynamic body}) async {
    final encoded = body is String ? body : jsonEncode(body ?? {});
    final response = await http.put(Uri.parse(url), body: encoded, headers: authHeaders);
    if (response.statusCode == 200) {
      return response.body;
    } else if (response.statusCode == 401) {
      final refreshed = await refreshToken(TokenStoreLocal.getRefreshToken());
      if (!refreshed) {
        TokenStoreLocal.removeToken();
        Get.offAllNamed(AppRouteName.login);
        return null;
      } else {
        final retryRes = await http.put(Uri.parse(url), body: encoded, headers: authHeaders);
        return retryRes.statusCode == 200 ? retryRes.body : null;
      }
    }
    return null;
  }

  @override
  Future<dynamic> deleteApi(String url) async {
    final response = await http.delete(Uri.parse(url), headers: authHeaders);
    if (response.statusCode == 200 || response.statusCode == 204) {
      return response.body;
    } else if (response.statusCode == 401) {
      final refreshed = await refreshToken(TokenStoreLocal.getRefreshToken());
      if (!refreshed) {
        TokenStoreLocal.removeToken();
        Get.offAllNamed(AppRouteName.login);
        return null;
      } else {
        final retryRes = await http.delete(Uri.parse(url), headers: authHeaders);
        return (retryRes.statusCode == 200 || retryRes.statusCode == 204) ? retryRes.body : null;
      }
    }
    return null;
  }
}
