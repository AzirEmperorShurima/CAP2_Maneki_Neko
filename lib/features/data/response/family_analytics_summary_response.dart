import 'package:json_annotation/json_annotation.dart';
import 'period_response.dart';

part 'family_analytics_summary_response.g.dart';

@JsonSerializable()
class FamilyAnalyticsSummaryResponse {
  final PeriodResponse? period;
  final FamilyAnalyticsTotalsResponse? totals;
  @JsonKey(name: 'memberSummary')
  final List<FamilyMemberSummaryResponse>? memberSummary;

  FamilyAnalyticsSummaryResponse({
    this.period,
    this.totals,
    this.memberSummary,
  });

  factory FamilyAnalyticsSummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$FamilyAnalyticsSummaryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyAnalyticsSummaryResponseToJson(this);
}

@JsonSerializable()
class FamilyAnalyticsTotalsResponse {
  final double? expense;
  final double? income;
  final double? balance;
  @JsonKey(name: 'transactionCount')
  final int? transactionCount;

  FamilyAnalyticsTotalsResponse({
    this.expense,
    this.income,
    this.balance,
    this.transactionCount,
  });

  factory FamilyAnalyticsTotalsResponse.fromJson(Map<String, dynamic> json) =>
      _$FamilyAnalyticsTotalsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyAnalyticsTotalsResponseToJson(this);
}

@JsonSerializable()
class FamilyMemberSummaryResponse {
  final double? income;
  final double? expense;
  @JsonKey(name: 'incomeCount')
  final int? incomeCount;
  @JsonKey(name: 'expenseCount')
  final int? expenseCount;
  @JsonKey(name: 'userId')
  final String? userId;
  final String? username;
  final String? email;
  final String? avatar;
  final double? balance;

  FamilyMemberSummaryResponse({
    this.income,
    this.expense,
    this.incomeCount,
    this.expenseCount,
    this.userId,
    this.username,
    this.email,
    this.avatar,
    this.balance,
  });

  factory FamilyMemberSummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$FamilyMemberSummaryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyMemberSummaryResponseToJson(this);
}
