import 'package:json_annotation/json_annotation.dart';

import 'overall_model.dart';

part 'analysis_model.g.dart';

@JsonSerializable()
class AnalysisModel {
  final OverallModel? overall;

  AnalysisModel({
    this.overall,
  });

  factory AnalysisModel.fromJson(Map<String, dynamic> json) => _$AnalysisModelFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisModelToJson(this);
}