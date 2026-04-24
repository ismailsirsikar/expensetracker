import 'package:dio/dio.dart';

import 'package:expensetracker/core/network/api_paths.dart';
import 'package:expensetracker/core/network/auth_interceptor.dart';
import 'package:expensetracker/core/network/interceptors/error_interceptor.dart';
import 'package:expensetracker/core/network/interceptors/logging_interceptor.dart';
import 'package:expensetracker/core/network/session_manager.dart';
import 'package:expensetracker/data/models/auth_response_model.dart';

typedef RefreshTokenCallback =
    Future<AuthResponseModel> Function(String refreshToken);

class DioClient {
  final Dio dio;
  final SessionManager sessionManager;

  DioClient._({required this.dio, required this.sessionManager});

  factory DioClient({
    required SessionManager sessionManager,
    required RefreshTokenCallback refreshTokenCallback,
    String baseUrl = ApiPaths.baseUrl,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
        sendTimeout: const Duration(minutes: 2),
        responseType: ResponseType.json,
        followRedirects: true,
        maxRedirects: 5,
        validateStatus: (status) => status != null && status < 400,
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(
        dio: dio,
        sessionManager: sessionManager,
        refreshTokenCallback: refreshTokenCallback,
      ),
      ErrorInterceptor(),
      LoggingInterceptor(),
    ]);

    return DioClient._(dio: dio, sessionManager: sessionManager);
  }
}
