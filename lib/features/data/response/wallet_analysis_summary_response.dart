import 'package:json_annotation/json_annotation.dart';

part 'wallet_analysis_summary_response.g.dart';

@JsonSerializable()
class WalletAnalysisSummaryResponse {
  @JsonKey(name: 'totalIncome')
  final num? totalIncome;

  @JsonKey(name: 'totalExpense')
  final num? totalExpense;

  @JsonKey(name: 'incomeCount')
  final int? incomeCount;

  @JsonKey(name: 'expenseCount')
  final int? expenseCount;

  @JsonKey(name: 'net')
  final num? net;

  WalletAnalysisSummaryResponse({
    this.totalIncome,
    this.totalExpense,
    this.incomeCount,
    this.expenseCount,
    this.net,
  });

  factory WalletAnalysisSummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$WalletAnalysisSummaryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WalletAnalysisSummaryResponseToJson(this);
}
