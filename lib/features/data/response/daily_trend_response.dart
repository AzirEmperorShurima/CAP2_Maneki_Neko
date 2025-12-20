import 'package:json_annotation/json_annotation.dart';

part 'daily_trend_response.g.dart';

@JsonSerializable()
class DailyTrendResponse {
  final String? date;
  final num? income;
  final num? expense;

  DailyTrendResponse({
    this.date,
    this.income,
    this.expense,
  });

  factory DailyTrendResponse.fromJson(Map<String, dynamic> json) =>
      _$DailyTrendResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DailyTrendResponseToJson(this);
}
