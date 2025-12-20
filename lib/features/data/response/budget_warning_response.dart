import 'package:json_annotation/json_annotation.dart';

import 'budget_warning_item_response.dart';

part 'budget_warning_response.g.dart';

@JsonSerializable()
class BudgetWarningResponse {
  final int? count;

  final bool? hasError;

  final bool? hasCritical;

  final List<BudgetWarningItemResponse>? warnings;

  BudgetWarningResponse({
    this.count,
    this.hasError,
    this.hasCritical,
    this.warnings,
  });

  factory BudgetWarningResponse.fromJson(Map<String, dynamic> json) =>
      _$BudgetWarningResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BudgetWarningResponseToJson(this);
}
