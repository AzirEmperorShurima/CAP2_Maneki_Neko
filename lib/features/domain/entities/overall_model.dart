import 'package:finance_management_app/features/domain/entities/amount_model.dart';
import 'package:json_annotation/json_annotation.dart';

import 'period_model.dart';

part 'overall_model.g.dart';

@JsonSerializable()
class OverallModel {
  final AmountModel? income;

  final AmountModel? expense;

  final num? netBalance;

  final num? totalWalletBalance;

  final num? walletsCount;

  final PeriodModel? period;

  OverallModel({
    this.income,
    this.expense,
    this.netBalance,
    this.totalWalletBalance,
    this.walletsCount,
    this.period,
  });

  factory OverallModel.fromJson(Map<String, dynamic> json) => _$OverallModelFromJson(json);

  Map<String, dynamic> toJson() => _$OverallModelToJson(this);
}