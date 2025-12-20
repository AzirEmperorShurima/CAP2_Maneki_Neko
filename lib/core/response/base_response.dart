import 'package:json_annotation/json_annotation.dart';

part 'base_response.g.dart';

@JsonSerializable()
class BaseResponse {
  dynamic data;

  int? code;

  String? message;

  String? errors;

  BaseResponse();

  factory BaseResponse.fromJson(Map<String, dynamic> json) =>
      _$BaseResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BaseResponseToJson(this);

  /// Helper method để parse nested data từ response
  /// 
  /// [decoder] - Function để decode từ Map<String, dynamic> thành object
  /// [fromKey] - Key trong data object cần lấy (ví dụ: 'user', 'data')
  /// [from] - Custom function để transform data trước khi decode
  /// 
  /// Ví dụ:
  /// ```dart
  /// response.getBody(UserResponse.fromJson, fromKey: 'user')?.toUserModel()
  /// ```
  T? getBody<T>(
    T Function(Map<String, dynamic>) decoder, {
    String? fromKey,
    dynamic Function(dynamic data)? from,
  }) {
    if (fromKey != null && data is Map && data[fromKey] is Map) {
      return decoder(data[fromKey] as Map<String, dynamic>);
    }

    if (from != null && data is Map && from(data) is Map) {
      return decoder(from(data) as Map<String, dynamic>);
    }

    if (data is Map) {
      return decoder(data as Map<String, dynamic>);
    }

    return null;
  }

  /// Helper method để parse list từ response
  /// 
  /// [decoder] - Function để decode từ Map<String, dynamic> thành object
  /// [fromKey] - Key trong data object cần lấy list (ví dụ: 'transactions', 'items')
  /// [from] - Custom function để transform data và trả về List trước khi decode
  /// [valueFromKey] - Key trong mỗi item của list để lấy value cần decode (nếu item là Map)
  /// 
  /// Ví dụ với response: {"message": "...", "data": {"transactions": [...]}}
  /// Trong trường hợp này, BaseResponse.data = {"transactions": [...]}
  /// ```dart
  /// response.getItems(TransactionResponse.fromJson, fromKey: 'transactions')
  /// ```
  /// 
  /// Hoặc nếu response có nested structure: {"data": {"data": {"transactions": [...]}}}
  /// ```dart
  /// response.getItems(
  ///   TransactionResponse.fromJson,
  ///   from: (data) => data is Map ? (data['data'] as Map?)?['transactions'] : null,
  /// )
  /// ```
  List<T>? getItems<T>(
    T Function(Map<String, dynamic>) decoder, {
    /// Get value from key when data response is Map and contain key {fromKey}
    String? fromKey,
    List<dynamic>? Function(dynamic data)? from,
    /// Get value from each item in list to decode to model, item is Map and item contain key {valueFromKey}
    String? valueFromKey,
  }) {
    // Nếu có from function, dùng nó để lấy list
    if (from != null && data is Map) {
      final list = from(data);
      if (list != null) {
        return list
            .where((element) {
              if (valueFromKey != null) {
                return element is Map && element[valueFromKey] is Map;
              }
              return element is Map;
            })
            .map((e) {
              if (valueFromKey != null && e is Map && e[valueFromKey] is Map) {
                return decoder(e[valueFromKey] as Map<String, dynamic>);
              }
              return decoder(e as Map<String, dynamic>);
            })
            .toList();
      }
    }

    // Nếu có fromKey, lấy list từ data[fromKey]
    if (fromKey != null && data is Map && data[fromKey] is List) {
      return (data[fromKey] as List)
          .where((element) {
            if (valueFromKey != null) {
              return element is Map && element[valueFromKey] is Map;
            }
            return element is Map;
          })
          .map((e) {
            if (valueFromKey != null && e is Map && e[valueFromKey] is Map) {
              return decoder(e[valueFromKey] as Map<String, dynamic>);
            }
            return decoder(e as Map<String, dynamic>);
          })
          .whereType<T>()
          .toList();
    }

    // Nếu data là List trực tiếp
    if (data is List) {
      return (data as List)
          .where((element) {
            if (valueFromKey != null) {
              return element is Map && element[valueFromKey] is Map;
            }
            return element is Map;
          })
          .map((e) {
            if (valueFromKey != null && e is Map && e[valueFromKey] is Map) {
              return decoder(e[valueFromKey] as Map<String, dynamic>);
            }
            return decoder(e as Map<String, dynamic>);
          })
          .whereType<T>()
          .toList();
    }

    return null;
  }
}
