import 'package:json_annotation/json_annotation.dart';

part 'daily_trend_model.g.dart';

/// Model xu hướng theo ngày
@JsonSerializable()
class DailyTrendModel {
  final String? date;
  final num? income;
  final num? expense;

  DailyTrendModel({
    this.date,
    this.income,
    this.expense,
  });

  factory DailyTrendModel.fromJson(Map<String, dynamic> json) =>
      _$DailyTrendModelFromJson(json);

  Map<String, dynamic> toJson() => _$DailyTrendModelToJson(this);
}

