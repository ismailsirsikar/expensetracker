import 'package:dio/dio.dart';

import '../../core/network/api_paths.dart';
import '../../core/network/token_storage.dart';
import '../models/auth_response_model.dart';

class AuthService {
  final Dio dio;
  final TokenStorage tokenStorage;

  AuthService({required this.dio, required this.tokenStorage});

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
    await tokenStorage.saveTokens(authResponse);
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
    await tokenStorage.saveTokens(authResponse);
    return authResponse;
  }

  Future<AuthResponseModel> refreshToken() async {
    final refreshToken = await tokenStorage.getRefreshToken();
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
    await tokenStorage.saveTokens(authResponse);
    return authResponse;
  }

  Future<void> logout() async {
    await tokenStorage.clearTokens();
  }
}
