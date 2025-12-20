import 'package:json_annotation/json_annotation.dart';
import 'period_response.dart';

part 'family_user_breakdown_response.g.dart';

@JsonSerializable()
class FamilyUserBreakdownResponse {
  final PeriodResponse? period;
  final FamilyBreakdownSummaryResponse? summary;
  final List<FamilyBreakdownItemResponse>? breakdown;
  final FamilyBreakdownChartsResponse? charts;

  FamilyUserBreakdownResponse({
    this.period,
    this.summary,
    this.breakdown,
    this.charts,
  });

  factory FamilyUserBreakdownResponse.fromJson(Map<String, dynamic> json) =>
      _$FamilyUserBreakdownResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyUserBreakdownResponseToJson(this);
}

@JsonSerializable()
class FamilyBreakdownSummaryResponse {
  @JsonKey(name: 'totalExpense')
  final double? totalExpense;
  @JsonKey(name: 'totalIncome')
  final double? totalIncome;
  @JsonKey(name: 'totalTransactions')
  final int? totalTransactions;
  @JsonKey(name: 'memberCount')
  final int? memberCount;
  @JsonKey(name: 'familyBalance')
  final double? familyBalance;

  FamilyBreakdownSummaryResponse({
    this.totalExpense,
    this.totalIncome,
    this.totalTransactions,
    this.memberCount,
    this.familyBalance,
  });

  factory FamilyBreakdownSummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$FamilyBreakdownSummaryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyBreakdownSummaryResponseToJson(this);
}

@JsonSerializable()
class FamilyBreakdownItemResponse {
  @JsonKey(name: 'totalTransactions')
  final int? totalTransactions;
  @JsonKey(name: 'userId')
  final String? userId;
  final String? username;
  final String? email;
  final String? avatar;
  final FamilyBreakdownTransactionResponse? expense;
  final FamilyBreakdownTransactionResponse? income;
  final double? balance;

  FamilyBreakdownItemResponse({
    this.totalTransactions,
    this.userId,
    this.username,
    this.email,
    this.avatar,
    this.expense,
    this.income,
    this.balance,
  });

  factory FamilyBreakdownItemResponse.fromJson(Map<String, dynamic> json) =>
      _$FamilyBreakdownItemResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyBreakdownItemResponseToJson(this);
}

@JsonSerializable()
class FamilyBreakdownTransactionResponse {
  final double? total;
  final int? count;

  FamilyBreakdownTransactionResponse({
    this.total,
    this.count,
  });

  factory FamilyBreakdownTransactionResponse.fromJson(Map<String, dynamic> json) =>
      _$FamilyBreakdownTransactionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyBreakdownTransactionResponseToJson(this);
}

@JsonSerializable()
class FamilyBreakdownChartsResponse {
  final FamilyBreakdownChartDataResponse? expense;
  final FamilyBreakdownChartDataResponse? income;

  FamilyBreakdownChartsResponse({
    this.expense,
    this.income,
  });

  factory FamilyBreakdownChartsResponse.fromJson(Map<String, dynamic> json) =>
      _$FamilyBreakdownChartsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyBreakdownChartsResponseToJson(this);
}

@JsonSerializable()
class FamilyBreakdownChartDataResponse {
  final String? title;
  final List<FamilyBreakdownChartItemResponse>? data;
  final double? total;

  FamilyBreakdownChartDataResponse({
    this.title,
    this.data,
    this.total,
  });

  factory FamilyBreakdownChartDataResponse.fromJson(Map<String, dynamic> json) =>
      _$FamilyBreakdownChartDataResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyBreakdownChartDataResponseToJson(this);
}

@JsonSerializable()
class FamilyBreakdownChartItemResponse {
  final String? name;
  final double? value;
  final double? percentage;
  @JsonKey(name: 'userId')
  final String? userId;

  FamilyBreakdownChartItemResponse({
    this.name,
    this.value,
    this.percentage,
    this.userId,
  });

  factory FamilyBreakdownChartItemResponse.fromJson(Map<String, dynamic> json) =>
      _$FamilyBreakdownChartItemResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyBreakdownChartItemResponseToJson(this);
}
