import 'package:json_annotation/json_annotation.dart';

import 'daily_trend_response.dart';
import 'expense_by_category_response.dart';
import 'wallet_analysis_summary_response.dart';
import 'wallet_summary_response.dart';

part 'wallet_analysis_response.g.dart';

@JsonSerializable()
class WalletAnalysisResponse {
  final WalletSummaryResponse? wallet;
  
  final WalletAnalysisSummaryResponse? summary;

  @JsonKey(name: 'expenseByCategory')
  final List<ExpenseByCategoryResponse>? expenseByCategory;

  @JsonKey(name: 'incomeByCategory')
  final List<ExpenseByCategoryResponse>? incomeByCategory;

  @JsonKey(name: 'dailyTrend')
  final List<DailyTrendResponse>? dailyTrend;

  WalletAnalysisResponse({
    this.wallet,
    this.summary,
    this.expenseByCategory,
    this.incomeByCategory,
    this.dailyTrend,
  });

  factory WalletAnalysisResponse.fromJson(Map<String, dynamic> json) =>
      _$WalletAnalysisResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WalletAnalysisResponseToJson(this);
}
