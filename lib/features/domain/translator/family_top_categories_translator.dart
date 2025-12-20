import '../../data/response/family_top_categories_response.dart';
import '../entities/family_top_categories_model.dart';
import 'period_translator.dart';

extension FamilyTopCategoriesTranslator on FamilyTopCategoriesResponse {
  FamilyTopCategoriesModel toFamilyTopCategoriesModel() {
    return FamilyTopCategoriesModel(
      period: period?.toPeriodModel(),
      type: type,
      summary: summary?.toFamilyTopCategoriesSummaryModel(),
      categories: categories
          ?.map((item) => item.toFamilyTopCategoryItemModel())
          .toList(),
      chart: chart?.toFamilyTopCategoriesChartModel(),
    );
  }
}

extension FamilyTopCategoriesSummaryTranslator on FamilyTopCategoriesSummaryResponse {
  FamilyTopCategoriesSummaryModel toFamilyTopCategoriesSummaryModel() {
    return FamilyTopCategoriesSummaryModel(
      total: total,
      count: count,
      topCategoriesTotal: topCategoriesTotal,
      categoryCount: categoryCount,
    );
  }
}

extension FamilyTopCategoryItemTranslator on FamilyTopCategoryItemResponse {
  FamilyTopCategoryItemModel toFamilyTopCategoryItemModel() {
    return FamilyTopCategoryItemModel(
      total: total,
      count: count,
      categoryId: categoryId,
      categoryName: categoryName,
      percentage: percentage,
    );
  }
}

extension FamilyTopCategoriesChartTranslator on FamilyTopCategoriesChartResponse {
  FamilyTopCategoriesChartModel toFamilyTopCategoriesChartModel() {
    return FamilyTopCategoriesChartModel(
      title: title,
      data: data?.map((item) => item.toFamilyTopCategoryChartItemModel()).toList(),
      total: total,
    );
  }
}

extension FamilyTopCategoryChartItemTranslator on FamilyTopCategoryChartItemResponse {
  FamilyTopCategoryChartItemModel toFamilyTopCategoryChartItemModel() {
    return FamilyTopCategoryChartItemModel(
      name: name,
      value: value,
      percentage: percentage,
      categoryId: categoryId,
    );
  }
}
