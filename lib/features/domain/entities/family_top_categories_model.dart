import 'period_model.dart';

class FamilyTopCategoriesModel {
  final PeriodModel? period;
  final String? type;
  final FamilyTopCategoriesSummaryModel? summary;
  final List<FamilyTopCategoryItemModel>? categories;
  final FamilyTopCategoriesChartModel? chart;

  FamilyTopCategoriesModel({
    this.period,
    this.type,
    this.summary,
    this.categories,
    this.chart,
  });
}

class FamilyTopCategoriesSummaryModel {
  final double? total;
  final int? count;
  final double? topCategoriesTotal;
  final int? categoryCount;

  FamilyTopCategoriesSummaryModel({
    this.total,
    this.count,
    this.topCategoriesTotal,
    this.categoryCount,
  });
}

class FamilyTopCategoryItemModel {
  final double? total;
  final int? count;
  final String? categoryId;
  final String? categoryName;
  final double? percentage;

  FamilyTopCategoryItemModel({
    this.total,
    this.count,
    this.categoryId,
    this.categoryName,
    this.percentage,
  });
}

class FamilyTopCategoriesChartModel {
  final String? title;
  final List<FamilyTopCategoryChartItemModel>? data;
  final double? total;

  FamilyTopCategoriesChartModel({
    this.title,
    this.data,
    this.total,
  });
}

class FamilyTopCategoryChartItemModel {
  final String? name;
  final double? value;
  final double? percentage;
  final String? categoryId;

  FamilyTopCategoryChartItemModel({
    this.name,
    this.value,
    this.percentage,
    this.categoryId,
  });
}
