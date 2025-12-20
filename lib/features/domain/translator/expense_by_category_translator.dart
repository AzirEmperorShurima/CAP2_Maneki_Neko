import '../../data/response/expense_by_category_response.dart';
import '../entities/expense_by_category_model.dart';

extension ExpenseByCategoryTranslator on ExpenseByCategoryResponse {
  ExpenseByCategoryModel toExpenseByCategoryModel() {
    return ExpenseByCategoryModel(
      categoryId: categoryId,
      categoryName: categoryName,
      total: total,
      count: count,
      percentage: percentage,
      image: image,
    );
  }
}
