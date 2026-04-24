import 'dart:async';

import 'package:dio/dio.dart';
import 'package:expensetracker/data/models/auth_response_model.dart';

import 'session_manager.dart';

typedef RefreshTokenCallback = Future<AuthResponseModel> Function(String refreshToken);

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required SessionManager sessionManager,
    required this.refreshTokenCallback,
  })  : _dio = dio,
        _sessionManager = sessionManager;

  final Dio _dio;
  final SessionManager _sessionManager;
  final RefreshTokenCallback refreshTokenCallback;
  Completer<void>? _refreshCompleter;

  static const _statusUnauthorized = 401;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _sessionManager.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final requestOptions = err.requestOptions;

    if (response?.statusCode == _statusUnauthorized && !_shouldSkipRefresh(requestOptions.path)) {
      try {
        await _refreshTokens();
      } catch (_) {
        await _sessionManager.clearSession();
        return handler.next(err);
      }

      final newAccessToken = await _sessionManager.getAccessToken();
      if (newAccessToken == null || newAccessToken.isEmpty) {
        return handler.next(err);
      }

      final retryOptions = requestOptions
        ..headers = Map<String, dynamic>.from(requestOptions.headers)
        ..headers['Authorization'] = 'Bearer $newAccessToken';

      try {
        final response = await _dio.fetch(retryOptions);
        return handler.resolve(response);
      } catch (retryError) {
        return handler.next(retryError is DioException
            ? retryError
            : DioException(requestOptions: requestOptions, error: retryError));
      }
    }

    handler.next(err);
  }

  bool _shouldSkipRefresh(String path) {
    return path.contains('/auth/refresh') || path.contains('/auth/login') || path.contains('/auth/register');
  }

  Future<void> _refreshTokens() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<void>();
    try {
      final refreshToken = await _sessionManager.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw StateError('Refresh token is missing.');
      }

      final authResponse = await refreshTokenCallback(refreshToken);
      await _sessionManager.setSession(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );
      _refreshCompleter!.complete();
    } catch (error, stackTrace) {
      _refreshCompleter!.completeError(error, stackTrace);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }
}
