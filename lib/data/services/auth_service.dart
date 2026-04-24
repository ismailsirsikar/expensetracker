import 'package:dio/dio.dart';

import '../../core/network/api_paths.dart';
import '../../core/network/session_manager.dart';
import '../models/auth_response_model.dart';

class AuthService {
  final Dio dio;
  final SessionManager sessionManager;

  AuthService({required this.dio, required this.sessionManager});

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await dio.post(
      ApiPaths.authLogin,
      data: {'email': email, 'password': password},
    );
    final authResponse = AuthResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
    await sessionManager.setSession(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
    );
    return authResponse;
  }

  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await dio.post(
      ApiPaths.authRegister,
      data: {'name': name, 'email': email, 'password': password},
    );
    final authResponse = AuthResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
    await sessionManager.setSession(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
    );
    return authResponse;
  }

  Future<AuthResponseModel> refreshToken() async {
    final refreshToken = await sessionManager.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('Refresh token is missing.');
    }
    final response = await dio.post(
      ApiPaths.authRefresh,
      data: {'refreshToken': refreshToken},
    );
    final authResponse = AuthResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
    await sessionManager.setSession(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
    );
    return authResponse;
  }

  Future<void> logout() async {
    await sessionManager.clearSession();
  }
}
