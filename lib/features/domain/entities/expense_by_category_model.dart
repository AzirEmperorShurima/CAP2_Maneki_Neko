import 'package:json_annotation/json_annotation.dart';

import 'category_model.dart';

part 'expense_by_category_model.g.dart';

/// Model chi tiêu theo danh mục
/// Tái sử dụng CategoryModel thông qua categoryId và categoryName
@JsonSerializable()
class ExpenseByCategoryModel {
  @JsonKey(name: 'categoryId')
  final String? categoryId;

  @JsonKey(name: 'categoryName')
  final String? categoryName;

  final num? total;

  final int? count;

  final String? percentage;

  final String? image;

  ExpenseByCategoryModel({
    this.categoryId,
    this.categoryName,
    this.total,
    this.count,
    this.percentage,
    this.image,
  });

  factory ExpenseByCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$ExpenseByCategoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExpenseByCategoryModelToJson(this);

  /// Chuyển đổi sang CategoryModel để tái sử dụng
  CategoryModel? toCategoryModel() {
    if (categoryId == null || categoryName == null) return null;
    return CategoryModel(
      id: categoryId,
      name: categoryName,
      type: 'expense', // Mặc định là expense vì đây là expenseByCategory
    );
  }
}

