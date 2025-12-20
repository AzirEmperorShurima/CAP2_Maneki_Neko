import 'package:finance_management_app/features/data/response/category_analysis_response.dart';
import 'package:finance_management_app/features/domain/entities/category_analysis_model.dart';

extension CategoryAnalysisTranslator on CategoryAnalysisResponse {
  CategoryAnalysisModel toCategoryAnalysisModel() => CategoryAnalysisModel(
        type: type,
        categories: categories
            ?.map((item) => item.toCategoryAnalysisItem())
            .toList(),
        grandTotal: grandTotal,
      );
}

extension CategoryAnalysisItemTranslator on CategoryAnalysisItemResponse {
  CategoryAnalysisItem toCategoryAnalysisItem() => CategoryAnalysisItem(
        categoryId: categoryId,
        categoryName: categoryName,
        total: total,
        count: count,
        avgAmount: avgAmount,
        percentage: percentage,
      );
}
