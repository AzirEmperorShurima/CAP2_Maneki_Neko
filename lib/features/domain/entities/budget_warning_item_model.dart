import 'package:json_annotation/json_annotation.dart';

part 'budget_warning_item_model.g.dart';

@JsonSerializable()
class BudgetWarningItemModel {
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

  BudgetWarningItemModel({
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

  factory BudgetWarningItemModel.fromJson(Map<String, dynamic> json) =>
      _$BudgetWarningItemModelFromJson(json);
      
  Map<String, dynamic> toJson() => _$BudgetWarningItemModelToJson(this);
}
