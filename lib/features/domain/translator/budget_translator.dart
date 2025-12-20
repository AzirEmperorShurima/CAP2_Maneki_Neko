import '../../data/response/budget_response.dart';
import '../entities/budget_model.dart';

extension BudgetTranslator on BudgetResponse {
  BudgetModel toBudgetModel() {
    return BudgetModel(
      name: name,
      userId: userId,
      type: type,
      amount: amount,
      isDerived: isDerived,
      familyId: familyId,
      isShared: isShared,
      isActive: isActive,
      periodStart: periodStart,
      periodEnd: periodEnd,
      createdAt: createdAt,
      updatedAt: updatedAt,
      spentAmount: spentAmount,
      categoryId: categoryId,
      parentBudgetId: parentBudgetId,
      id: id,
    );
  }
}
