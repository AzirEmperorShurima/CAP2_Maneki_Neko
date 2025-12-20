import 'package:json_annotation/json_annotation.dart';

import 'daily_trend_model.dart';
import 'expense_by_category_model.dart';
import 'wallet_analysis_summary_model.dart';
import 'wallet_summary_model.dart';

part 'wallet_analysis_model.g.dart';

/// Model phân tích chi tiết ví
/// Tái sử dụng các model: WalletSummaryModel, WalletAnalysisSummaryModel, 
/// ExpenseByCategoryModel, DailyTrendModel
@JsonSerializable()
class WalletAnalysisModel {
  final WalletSummaryModel? wallet;
  
  final WalletAnalysisSummaryModel? summary;

  @JsonKey(name: 'expenseByCategory')
  final List<ExpenseByCategoryModel>? expenseByCategory;

  @JsonKey(name: 'incomeByCategory')
  final List<ExpenseByCategoryModel>? incomeByCategory;

  @JsonKey(name: 'dailyTrend')
  final List<DailyTrendModel>? dailyTrend;

  WalletAnalysisModel({
    this.wallet,
    this.summary,
    this.expenseByCategory,
    this.incomeByCategory,
    this.dailyTrend,
  });

  factory WalletAnalysisModel.fromJson(Map<String, dynamic> json) =>
      _$WalletAnalysisModelFromJson(json);

  Map<String, dynamic> toJson() => _$WalletAnalysisModelToJson(this);
}

