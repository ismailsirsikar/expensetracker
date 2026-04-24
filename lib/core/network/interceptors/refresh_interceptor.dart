import 'package:dio/dio.dart';

import 'package:expensetracker/data/models/auth_response_model.dart';
import '../token_storage.dart';

typedef RefreshTokenCallback =
    Future<AuthResponseModel> Function(String refreshToken);

class RefreshInterceptor extends Interceptor {
  final Dio dio;
  final TokenStorage tokenStorage;
  final RefreshTokenCallback refreshTokenCallback;

  RefreshInterceptor({
    required this.dio,
    required this.tokenStorage,
    required this.refreshTokenCallback,
  });

  bool _isRefreshPath(RequestOptions options) {
    return options.path.contains('/auth/refresh') ||
        options.uri.path.contains('/auth/refresh');
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;
    final statusCode = err.response?.statusCode;
    final shouldRetry =
        statusCode == 401 &&
        requestOptions.extra['retry'] != true &&
        !_isRefreshPath(requestOptions);

    if (!shouldRetry) {
      return handler.next(err);
    }

    final refreshToken = await tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return handler.next(err);
    }

    try {
      final authResponse = await refreshTokenCallback(refreshToken);
      await tokenStorage.saveTokens(authResponse);

      final updatedOptions = requestOptions.copyWith(
        headers: {
          ...requestOptions.headers,
          'Authorization': 'Bearer ${authResponse.accessToken}',
        },
        extra: {...requestOptions.extra, 'retry': true},
      );

      final response = await dio.fetch(updatedOptions);
      return handler.resolve(response);
    } catch (refreshError) {
      return handler.next(err);
    }
  }
}
