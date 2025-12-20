import 'package:json_annotation/json_annotation.dart';

part 'period_response.g.dart';

@JsonSerializable()
class PeriodResponse {
  final DateTime? startDate;

  final DateTime? endDate;

  PeriodResponse({
    this.startDate,
    this.endDate,
  });

  factory PeriodResponse.fromJson(Map<String, dynamic> json) => _$PeriodResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PeriodResponseToJson(this);
}