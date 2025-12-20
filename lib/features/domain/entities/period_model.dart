import 'package:json_annotation/json_annotation.dart';

part 'period_model.g.dart';

@JsonSerializable()
class PeriodModel {
  final DateTime? startDate;

  final DateTime? endDate;

  PeriodModel({
    this.startDate,
    this.endDate,
  });

  factory PeriodModel.fromJson(Map<String, dynamic> json) => _$PeriodModelFromJson(json);

  Map<String, dynamic> toJson() => _$PeriodModelToJson(this);
}