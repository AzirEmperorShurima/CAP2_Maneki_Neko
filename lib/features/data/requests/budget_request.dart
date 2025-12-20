import 'package:json_annotation/json_annotation.dart';

part 'budget_request.g.dart';

@JsonSerializable(includeIfNull: false)
class BudgetRequest {
  final String? name;

  final String? type;

  final num? amount;

  final bool? updateIfExists;

  BudgetRequest({
    this.name,
    this.type,
    this.amount,
    this.updateIfExists,
  });

  factory BudgetRequest.fromJson(Map<String, dynamic> json) => _$BudgetRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BudgetRequestToJson(this);
}