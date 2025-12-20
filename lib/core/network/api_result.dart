import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_result.freezed.dart';

@freezed
class ApiResult<T> with _$ApiResult<T> {
  const factory ApiResult.success({required T data}) = Success<T>;
  const factory ApiResult.failure({required String error}) = Failure<T>;
}

/// Extension methods để làm việc với ApiResult dễ dàng hơn
extension ApiResultExtension<T> on ApiResult<T> {
  /// Kiểm tra xem result có phải là success không
  bool get isSuccess => this is Success<T>;

  /// Kiểm tra xem result có phải là failure không
  bool get isFailure => this is Failure<T>;

  /// Lấy data nếu là success, null nếu là failure
  T? get dataOrNull => when(
        success: (data) => data,
        failure: (_) => null,
      );

  /// Lấy error nếu là failure, null nếu là success
  String? get errorOrNull => when(
        success: (_) => null,
        failure: (error) => error,
      );

  /// Lấy data (throw exception nếu là failure)
  T get data => when(
        success: (data) => data,
        failure: (error) => throw Exception(error),
      );

  /// Lấy error (throw exception nếu là success)
  String get error => when(
        success: (_) => throw Exception('Cannot get error from success result'),
        failure: (error) => error,
      );
}

