import '../core/services/api_service.dart';
import '../data/local/token_store_local.dart';
import '../models/login/LoginRequest.dart';
import '../models/login/LoginResponse.dart';

abstract class AuthRepository {
  Future<LoginResponse> login(String phoneNumber, String password);
  Future<void> logout();
  bool isLoggedIn();
  Map<String, dynamic>? getCurrentUser();
  String getCurrentRole();
}

class AuthRepositoryImpl implements AuthRepository {
  final ApiService apiService;

  AuthRepositoryImpl({required this.apiService});

  @override
  Future<LoginResponse> login(String phoneNumber, String password) async {
    final response = await apiService.login(
      body: LoginRequest(phoneNumber: phoneNumber, password: password),
    );
    if (response.accessToken != null && response.accessToken!.isNotEmpty) {
      TokenStoreLocal.setAccessToken(response.accessToken ?? "");
      TokenStoreLocal.setRefreshToken(response.refreshToken ?? "");
      if (response.user != null) {
        TokenStoreLocal.setUser(response.user!.toJson());
      }
    }
    return response;
  }

  @override
  Future<void> logout() async {
    TokenStoreLocal.removeToken(redirect: true);
  }

  @override
  bool isLoggedIn() {
    return TokenStoreLocal.hasToken();
  }

  @override
  Map<String, dynamic>? getCurrentUser() {
    return TokenStoreLocal.getUser();
  }

  @override
  String getCurrentRole() {
    return TokenStoreLocal.getUserRole();
  }
}

