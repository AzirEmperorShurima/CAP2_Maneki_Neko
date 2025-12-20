import 'package:dio/dio.dart';
import 'package:finance_management_app/core/di/injector.dart';
import 'package:finance_management_app/core/exceptions/api_exceptions.dart';
import 'package:finance_management_app/core/logger/logger.dart';
import 'package:finance_management_app/core/network/api_result.dart';
import 'package:finance_management_app/core/response/base_response.dart';
import 'package:finance_management_app/features/app/presentation/bloc/app_cubit.dart';

/// Base repository với error handling tập trung
/// Tất cả repository nên extend từ class này
abstract class BaseRepository {
  /// Xử lý API response và convert thành ApiResult
  /// 
  /// [apiCall] - Function gọi API
  /// [forceLogout] - Có tự động logout khi 401 không (default: true)
  Future<ApiResult<T>> handleApiResponse<T>(
    Future<dynamic> Function() apiCall, {
    bool forceLogout = true,
  }) async {
    try {
      final response = await apiCall();
      
      // Với delete operations (void type), response có thể là BaseResponse với data rỗng (204 No Content)
      // Nếu response là BaseResponse object, coi như thành công (không cần check data field)
      if (response is BaseResponse) {
        // BaseResponse object tồn tại = request thành công
        // Với void type, return success (response sẽ được xử lý bởi type system)
        // Sử dụng helper để cast an toàn
        return _createSuccessResult<T>(response);
      }
      
      // Nếu response là null hoặc không có data
      if (response == null) {
        return const ApiResult.failure(error: 'No data in response');
      }

      // Nếu response có data, trả về success
      return ApiResult.success(data: response as T);
    } on DioException catch (e) {
      // Xử lý DioException
      if (e.error is ApiException) {
        final apiException = e.error as ApiException;
        
        // Tự động logout nếu là UnauthorizedException
        if (forceLogout && apiException is UnauthorizedException) {
          // Tự động logout và navigate về login khi token không hợp lệ
          getIt<AppCubit>().logout();
        }
        
        return ApiResult.failure(error: apiException.message);
      }

      // Xử lý các loại DioException khác
      final message = _handleDioException(e);
      
      // Tự động logout nếu là 401 Unauthorized
      if (forceLogout && e.response?.statusCode == 401) {
        getIt<AppCubit>().logout();
      }
      
      return ApiResult.failure(error: message);
    } on ApiException catch (e) {
      // Xử lý ApiException trực tiếp
      if (forceLogout && e is UnauthorizedException) {
        // Tự động logout và navigate về login khi token không hợp lệ
        getIt<AppCubit>().logout();
      }
      return ApiResult.failure(error: e.message);
    } catch (e, stackTrace) {
      // Xử lý các exception khác
      // Log chi tiết để debug
      logE(
        {
          'type': 'UnexpectedException',
          'error': e.toString(),
          'errorType': e.runtimeType.toString(),
        },
        stackTrace,
        e,
      );
      return ApiResult.failure(error: 'Unexpected error: ${e.toString()}');
    }
  }

  /// Helper để tạo success result, xử lý void type đặc biệt
  ApiResult<T> _createSuccessResult<T>(dynamic data) {
    // Với void type, return success với data là response (BaseResponse)
    // Dart sẽ tự xử lý type inference
    // Sử dụng unsafe cast để tránh lỗi compile time
    return ApiResult.success(data: data as T);
  }

  /// Xử lý DioException và trả về error message
  String _handleDioException(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      return data['message'] as String? ?? 'Request failed';
    }
    
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connection timed out. Please try again.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        switch (statusCode) {
          case 400:
            return 'Bad request';
          case 401:
            return 'Unauthorized. Please login again.';
          case 403:
            return 'Access denied.';
          case 404:
            return 'Resource not found.';
          case 500:
            return 'Server error. Please try again later.';
          default:
            return 'Server error occurred.';
        }
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      default:
        return 'Unexpected error occurred.';
    }
  }
}

