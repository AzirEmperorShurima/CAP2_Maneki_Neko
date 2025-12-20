import 'package:json_annotation/json_annotation.dart';

part 'budget_response.g.dart';

@JsonSerializable()
class BudgetResponse {
  final String? name;

  final String? userId;

  final String? type;

  final num? amount;

  final bool? isDerived;

  final String? familyId;

  final bool? isShared;

  final bool? isActive;

  final DateTime? periodStart;

  final DateTime? periodEnd;

  final DateTime? createdAt;

  final DateTime? updatedAt;

  final num? spentAmount;

  final String? id;

  final String? categoryId;

  final String? parentBudgetId;

  BudgetResponse({
    this.name,
    this.userId,
    this.type,
    this.amount,
    this.isDerived,
    this.familyId,
    this.isShared,
    this.isActive,
    this.periodStart,
    this.periodEnd,
    this.createdAt,
    this.updatedAt,
    this.spentAmount,
    this.id,
    this.categoryId,
    this.parentBudgetId,
  });

  factory BudgetResponse.fromJson(Map<String, dynamic> json) =>
      _$BudgetResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BudgetResponseToJson(this);
}
