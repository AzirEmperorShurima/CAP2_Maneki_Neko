import 'package:json_annotation/json_annotation.dart';

part 'transaction_request.g.dart';

class DateTimeUtcConverter implements JsonConverter<DateTime?, String?> {
  const DateTimeUtcConverter();

  @override
  DateTime? fromJson(String? json) {
    if (json == null) return null;
    return DateTime.parse(json).toUtc();
  }

  @override
  String? toJson(DateTime? object) {
    if (object == null) return null;
    return object.toUtc().toIso8601String();
  }
}

@JsonSerializable()
class TransactionRequest {
  final num? amount;

  final String? type;

  final String? description;

  final String? categoryId;

  @DateTimeUtcConverter()
  final DateTime? date;

  final String? walletId;

  @JsonKey(name: 'expense_for')
  final String? memberType;

  TransactionRequest({
    this.type,
    this.amount,
    this.description,
    this.categoryId,
    this.date,
    this.walletId,
    this.memberType,
  });

  factory TransactionRequest.fromJson(Map<String, dynamic> json) =>
      _$TransactionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionRequestToJson(this);
}
