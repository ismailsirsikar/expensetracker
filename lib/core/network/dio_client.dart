import 'package:dio/dio.dart';

import 'package:expensetracker/data/models/auth_response_model.dart';
import 'token_storage.dart';
import 'api_paths.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/refresh_interceptor.dart';

typedef RefreshTokenCallback =
    Future<AuthResponseModel> Function(String refreshToken);

class DioClient {
  final Dio dio;
  final TokenStorage tokenStorage;

  DioClient._({required this.dio, required this.tokenStorage});

  factory DioClient({
    required TokenStorage tokenStorage,
    required RefreshTokenCallback refreshTokenCallback,
    String baseUrl = ApiPaths.baseUrl,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        responseType: ResponseType.json,
        followRedirects: true,
        maxRedirects: 5,
        validateStatus: (status) => status != null && status < 400,
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(tokenStorage),
      RefreshInterceptor(
        dio: dio,
        tokenStorage: tokenStorage,
        refreshTokenCallback: refreshTokenCallback,
      ),
      ErrorInterceptor(),
      LoggingInterceptor(),
    ]);

    return DioClient._(dio: dio, tokenStorage: tokenStorage);
  }
}
