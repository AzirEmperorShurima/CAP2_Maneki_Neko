import 'package:finance_management_app/features/domain/entities/budget_warning_item_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'budget_warning_model.g.dart';

@JsonSerializable()
class BudgetWarningModel {
  final int? count;

  final bool? hasError;

  final bool? hasCritical;
  
  final List<BudgetWarningItemModel>? warnings;

  BudgetWarningModel({
    this.count,
    this.hasError,
    this.hasCritical,
    this.warnings,
  });

  factory BudgetWarningModel.fromJson(Map<String, dynamic> json) =>
      _$BudgetWarningModelFromJson(json);
  Map<String, dynamic> toJson() => _$BudgetWarningModelToJson(this);
}
