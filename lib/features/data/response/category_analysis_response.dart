import 'package:json_annotation/json_annotation.dart';

part 'category_analysis_response.g.dart';

@JsonSerializable()
class CategoryAnalysisResponse {
  final String? type;
  final List<CategoryAnalysisItemResponse>? categories;
  @JsonKey(name: 'grandTotal')
  final double? grandTotal;

  CategoryAnalysisResponse({
    this.type,
    this.categories,
    this.grandTotal,
  });

  factory CategoryAnalysisResponse.fromJson(Map<String, dynamic> json) =>
      _$CategoryAnalysisResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryAnalysisResponseToJson(this);
}

@JsonSerializable()
class CategoryAnalysisItemResponse {
  @JsonKey(name: 'categoryId')
  final String? categoryId;
  @JsonKey(name: 'categoryName')
  final String? categoryName;
  final double? total;
  final int? count;
  @JsonKey(name: 'avgAmount')
  final double? avgAmount;
  final String? percentage;

  CategoryAnalysisItemResponse({
    this.categoryId,
    this.categoryName,
    this.total,
    this.count,
    this.avgAmount,
    this.percentage,
  });

  factory CategoryAnalysisItemResponse.fromJson(Map<String, dynamic> json) =>
      _$CategoryAnalysisItemResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryAnalysisItemResponseToJson(this);
}
