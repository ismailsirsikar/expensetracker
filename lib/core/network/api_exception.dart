import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Object? originalError;

  ApiException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';

  factory ApiException.fromDioException(DioException exception) {
    final statusCode = exception.response?.statusCode;
    final responseData = exception.response?.data;
    final message =
        _parseMessage(responseData) ??
        exception.message ??
        'An unexpected error occurred';

    if (statusCode == 400) {
      return BadRequestException(
        message,
        statusCode: statusCode,
        originalError: exception,
        details: responseData,
      );
    }
    if (statusCode == 401) {
      return AuthenticationException(
        message,
        statusCode: statusCode,
        originalError: exception,
      );
    }
    if (statusCode == 403) {
      return AuthorizationException(
        message,
        statusCode: statusCode,
        originalError: exception,
      );
    }
    if (statusCode == 404) {
      return NotFoundException(
        message,
        statusCode: statusCode,
        originalError: exception,
      );
    }
    if (statusCode != null && statusCode >= 500) {
      return ServerException(
        message,
        statusCode: statusCode,
        originalError: exception,
      );
    }
    if (exception.type == DioExceptionType.connectionTimeout) {
      return NetworkException(
        'Connection timed out. Check your internet connection and try again.',
        originalError: exception,
      );
    }
    if (exception.type == DioExceptionType.receiveTimeout) {
      return NetworkException(
        'Server took too long to respond. Please try again later.',
        originalError: exception,
      );
    }
    if (exception.type == DioExceptionType.sendTimeout) {
      return NetworkException(
        'Request timed out while sending data. Please try again.',
        originalError: exception,
      );
    }
    if (exception.type == DioExceptionType.connectionError) {
      return NetworkException(
        'Unable to reach the server. Please check your internet connection.',
        originalError: exception,
      );
    }
    return ApiException(
      message,
      statusCode: statusCode,
      originalError: exception,
    );
  }

  static String? _parseMessage(Object? responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData['message'] is String) {
        return responseData['message'] as String;
      }
      if (responseData['error'] is String) {
        return responseData['error'] as String;
      }
    }
    return null;
  }
}

class AuthenticationException extends ApiException {
  AuthenticationException(
    super.message, {
    super.statusCode,
    super.originalError,
  });
}

class RefreshTokenException extends AuthenticationException {
  RefreshTokenException(super.message, {super.statusCode, super.originalError});
}

class AuthorizationException extends ApiException {
  AuthorizationException(
    super.message, {
    super.statusCode,
    super.originalError,
  });
}

class BadRequestException extends ApiException {
  final Object? details;

  BadRequestException(
    super.message, {
    super.statusCode,
    super.originalError,
    this.details,
  });
}

class NotFoundException extends ApiException {
  NotFoundException(super.message, {super.statusCode, super.originalError});
}

class ServerException extends ApiException {
  ServerException(super.message, {super.statusCode, super.originalError});
}

class NetworkException extends ApiException {
  NetworkException(super.message, {super.statusCode, super.originalError});
}
