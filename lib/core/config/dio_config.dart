import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:finance_management_app/core/infrastructure/secure_storage_service.dart';
import 'package:finance_management_app/core/constants/endpoints.dart';
import 'package:finance_management_app/core/interceptors/auth_interceptor.dart';
import 'package:finance_management_app/core/exceptions/api_exceptions.dart';

class DioConfig {
  static Dio createDio(SecureStorageService storage) {
    final baseUrl = ApiConfig.baseUrl;

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Throw DioException for any 4xx/5xx to let Bloc catch via try/catch
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    // Reset and add interceptors
    dio.interceptors.clear();
    dio.interceptors.addAll([
      _LoggerInterceptor(),
      AuthInterceptor(storage),
      _ErrorInterceptor(),
    ]);

    return dio;
  }
}

class _LoggerInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print('REQUEST[${options.method}] => PATH: ${options.path}');
      if (options.headers.isNotEmpty) print('Headers: ${options.headers}');
      if (options.data != null) print('Data: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
      print('Response: ${response.data}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
      print('Message: ${err.message}');
    }
    handler.next(err);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('ErrorType: ${err.type} - Message: ${err.message}');
    }

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      handler.next(err.copyWith(error: ApiTimeoutException()));
      return;
    }

    if (err.type == DioExceptionType.badResponse) {
      final status = err.response?.statusCode ?? 0;
      final serverMessage = err.response?.data is Map<String, dynamic>
          ? (err.response?.data['message'] as String?)
          : null;
      switch (status) {
        case 400:
          handler.next(err.copyWith(error: BadRequestException(serverMessage ?? 'Bad request')));
          return;
        case 401:
          handler.next(err.copyWith(error: UnauthorizedException(serverMessage ?? 'Unauthorized. Please login again.')));
          return;
        case 403:
          handler.next(err.copyWith(error: ForbiddenException(serverMessage ?? 'Access denied.')));
          return;
        case 404:
          handler.next(err.copyWith(error: NotFoundException(serverMessage ?? 'Resource not found.')));
          return;
        case 500:
          handler.next(err.copyWith(error: ServerException(serverMessage ?? 'Server error. Please try again later.')));
          return;
        default:
          handler.next(err.copyWith(error: ServerException(serverMessage ?? 'Server error occurred.')));
          return;
      }
    }

    handler.next(err.copyWith(error: ServerException('Unexpected error')));
  }
}