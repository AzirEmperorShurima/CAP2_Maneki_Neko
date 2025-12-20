import 'package:json_annotation/json_annotation.dart';

import 'amount_response.dart';
import 'period_response.dart';

part 'overall_response.g.dart';

@JsonSerializable()
class OverallResponse {
  final AmountResponse? income;

  final AmountResponse? expense;

  final num? netBalance;

  final num? totalWalletBalance;

  final num? walletsCount;

  final PeriodResponse? period;

  OverallResponse({
    this.income,
    this.expense,
    this.netBalance,
    this.totalWalletBalance,
    this.walletsCount,
    this.period,
  });

  factory OverallResponse.fromJson(Map<String, dynamic> json) => _$OverallResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OverallResponseToJson(this);
}