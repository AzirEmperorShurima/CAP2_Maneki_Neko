import 'package:json_annotation/json_annotation.dart';

import 'overall_response.dart';

part 'analysis_response.g.dart';

@JsonSerializable()
class AnalysisResponse {
  final OverallResponse? overall;

  AnalysisResponse({
    this.overall,
  });

  factory AnalysisResponse.fromJson(Map<String, dynamic> json) => _$AnalysisResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisResponseToJson(this);
}