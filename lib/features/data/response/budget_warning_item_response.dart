import 'package:json_annotation/json_annotation.dart';

part 'budget_warning_item_response.g.dart';

@JsonSerializable()
class BudgetWarningItemResponse {
  final String? budgetId;

  final String? budgetType;

  final String? category;

  final num? spent;

  final num? total;

  final num? remaining;

  final num? percentUsed;

  final String? level;

  final String? type;

  final String? message;

  final num? overage;

  BudgetWarningItemResponse({
    this.budgetId,
    this.budgetType,
    this.category,
    this.spent,
    this.total,
    this.remaining,
    this.percentUsed,
    this.level,
    this.type,
    this.message,
    this.overage,
  });

  factory BudgetWarningItemResponse.fromJson(Map<String, dynamic> json) =>
      _$BudgetWarningItemResponseFromJson(json);
      
  Map<String, dynamic> toJson() => _$BudgetWarningItemResponseToJson(this);
}
