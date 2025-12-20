import 'package:finance_management_app/features/data/response/budget_warning_item_response.dart';
import 'package:finance_management_app/features/domain/entities/budget_warning_item_model.dart';

extension BudgetWarningItemTranslator on BudgetWarningItemResponse {
  BudgetWarningItemModel toBudgetWarningItemModel() {
    return BudgetWarningItemModel(
      budgetId: budgetId,
      budgetType: budgetType,
      category: category,
      spent: spent,
      total: total,
      remaining: remaining,
      percentUsed: percentUsed,
      level: level,
      type: type,
      message: message,
      overage: overage,
    );
  }
}