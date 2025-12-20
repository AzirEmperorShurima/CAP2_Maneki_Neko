import 'package:json_annotation/json_annotation.dart';

part 'expense_by_category_response.g.dart';

@JsonSerializable()
class ExpenseByCategoryResponse {
  @JsonKey(name: 'categoryId')
  final String? categoryId;

  @JsonKey(name: 'categoryName')
  final String? categoryName;

  final num? total;

  final int? count;

  final String? percentage;

  final String? image;

  ExpenseByCategoryResponse({
    this.categoryId,
    this.categoryName,
    this.total,
    this.count,
    this.percentage,
    this.image,
  });

  factory ExpenseByCategoryResponse.fromJson(Map<String, dynamic> json) =>
      _$ExpenseByCategoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ExpenseByCategoryResponseToJson(this);
}
