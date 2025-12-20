import 'package:dio/dio.dart';
import 'package:finance_management_app/core/exceptions/api_exceptions.dart';
import 'package:finance_management_app/core/logger/logger.dart';

/// ExceptionHandler - Tập trung xử lý exception và log
class ExceptionHandler {
  /// Xử lý exception và trả về ApiException tương ứng
  /// 
  /// [e] - Exception cần xử lý
  /// [stackTrace] - Stack trace (optional)
  static ApiException handler(Exception e, [StackTrace? stackTrace]) {
    if (e is DioException) {
      // Log chi tiết DioException
      logE(
        {
          'type': 'DioException',
          'statusCode': e.response?.statusCode,
          'statusMessage': e.response?.statusMessage,
          'url': e.response?.realUri.toString() ?? e.requestOptions.path,
          'response': e.response?.data,
          'errorType': e.type.toString(),
        },
        stackTrace ?? e.stackTrace,
        e,
      );
      return _dioExceptionHandler(e);
    } else {
      // Log exception khác
      logE('Exception: ${e.toString()}', stackTrace, e);
      return ApiException(e.toString());
    }
  }

  /// Xử lý DioException và trả về ApiException tương ứng
  static ApiException _dioExceptionHandler(DioException e) {
    switch (e.type) {
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiTimeoutException();

      case DioExceptionType.connectionError:
        return NoInternetConnectionException();

      case DioExceptionType.badResponse:
        // Xử lý bad response
        if (e.response?.data is! Map) {
          return ServerException('Server error occurred.');
        }

        final data = e.response!.data as Map<String, dynamic>;
        final statusCode = e.response?.statusCode;

        // Lấy message từ response
        String? message;
        if (data['errors'] is String) {
          message = data['errors'] as String;
        } else if (data['message'] is String) {
          message = data['message'] as String;
        }

        // Map status code thành exception tương ứng
        switch (statusCode) {
          case 400:
            return BadRequestException(message ?? 'Bad request');
          case 401:
            return UnauthorizedException(message ?? 'Unauthorized. Please login again.');
          case 403:
            return ForbiddenException(message ?? 'Access denied.');
          case 404:
            return NotFoundException(message ?? 'Resource not found.');
          case 500:
          default:
            return ServerException(message ?? 'Server error. Please try again later.');
        }

      case DioExceptionType.cancel:
        return const ApiException('Request cancelled');

      case DioExceptionType.unknown:
      default:
        return ServerException('Unexpected error occurred.');
    }
  }
}

