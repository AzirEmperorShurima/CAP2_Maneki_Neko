import 'package:json_annotation/json_annotation.dart';
import 'period_response.dart';

part 'family_top_categories_response.g.dart';

@JsonSerializable()
class FamilyTopCategoriesResponse {
  final PeriodResponse? period;
  final String? type;
  final FamilyTopCategoriesSummaryResponse? summary;
  final List<FamilyTopCategoryItemResponse>? categories;
  final FamilyTopCategoriesChartResponse? chart;

  FamilyTopCategoriesResponse({
    this.period,
    this.type,
    this.summary,
    this.categories,
    this.chart,
  });

  factory FamilyTopCategoriesResponse.fromJson(Map<String, dynamic> json) =>
      _$FamilyTopCategoriesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyTopCategoriesResponseToJson(this);
}

@JsonSerializable()
class FamilyTopCategoriesSummaryResponse {
  final double? total;
  final int? count;
  @JsonKey(name: 'topCategoriesTotal')
  final double? topCategoriesTotal;
  @JsonKey(name: 'categoryCount')
  final int? categoryCount;

  FamilyTopCategoriesSummaryResponse({
    this.total,
    this.count,
    this.topCategoriesTotal,
    this.categoryCount,
  });

  factory FamilyTopCategoriesSummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$FamilyTopCategoriesSummaryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyTopCategoriesSummaryResponseToJson(this);
}

@JsonSerializable()
class FamilyTopCategoryItemResponse {
  final double? total;
  final int? count;
  @JsonKey(name: 'categoryId')
  final String? categoryId;
  @JsonKey(name: 'categoryName')
  final String? categoryName;
  final double? percentage;

  FamilyTopCategoryItemResponse({
    this.total,
    this.count,
    this.categoryId,
    this.categoryName,
    this.percentage,
  });

  factory FamilyTopCategoryItemResponse.fromJson(Map<String, dynamic> json) =>
      _$FamilyTopCategoryItemResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyTopCategoryItemResponseToJson(this);
}

@JsonSerializable()
class FamilyTopCategoriesChartResponse {
  final String? title;
  final List<FamilyTopCategoryChartItemResponse>? data;
  final double? total;

  FamilyTopCategoriesChartResponse({
    this.title,
    this.data,
    this.total,
  });

  factory FamilyTopCategoriesChartResponse.fromJson(Map<String, dynamic> json) =>
      _$FamilyTopCategoriesChartResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyTopCategoriesChartResponseToJson(this);
}

@JsonSerializable()
class FamilyTopCategoryChartItemResponse {
  final String? name;
  final double? value;
  final double? percentage;
  @JsonKey(name: 'categoryId')
  final String? categoryId;

  FamilyTopCategoryChartItemResponse({
    this.name,
    this.value,
    this.percentage,
    this.categoryId,
  });

  factory FamilyTopCategoryChartItemResponse.fromJson(Map<String, dynamic> json) =>
      _$FamilyTopCategoryChartItemResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyTopCategoryChartItemResponseToJson(this);
}
