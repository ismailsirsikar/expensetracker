import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('--> ${options.method} ${options.uri}');
      debugPrint('Headers: ${options.headers}');
      debugPrint('Body: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('<-- ${response.statusCode} ${response.requestOptions.uri}');
      debugPrint('Response: ${response.data}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '--> ERROR ${err.requestOptions.method} ${err.requestOptions.uri}',
      );
      debugPrint('Request headers: ${err.requestOptions.headers}');
      debugPrint('Request data: ${err.requestOptions.data}');
      debugPrint('Status code: ${err.response?.statusCode}');
      debugPrint('Response data: ${err.response?.data}');
      debugPrint(err.toString());
    }
    handler.next(err);
  }
}
