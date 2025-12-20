import 'package:json_annotation/json_annotation.dart';

part 'wallet_analysis_summary_model.g.dart';

/// Model tóm tắt phân tích ví
@JsonSerializable()
class WalletAnalysisSummaryModel {
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

  WalletAnalysisSummaryModel({
    this.totalIncome,
    this.totalExpense,
    this.incomeCount,
    this.expenseCount,
    this.net,
  });

  factory WalletAnalysisSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$WalletAnalysisSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$WalletAnalysisSummaryModelToJson(this);
}

