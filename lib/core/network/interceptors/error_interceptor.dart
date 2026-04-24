import 'package:dio/dio.dart';

import '../api_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final mapped = ApiException.fromDioException(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: mapped,
        response: err.response,
        type: err.type,
      ),
    );
  }
}
