import '../../data/response/budget_warning_response.dart';
import '../entities/budget_warning_model.dart';
import 'budget_warning_item_translator.dart';

extension BudgetWarningTranslator on BudgetWarningResponse {
  BudgetWarningModel toBudgetWarningModel() {
    return BudgetWarningModel(
      count: count,
      hasError: hasError,
      hasCritical: hasCritical,
      warnings: warnings?.map((e) => e.toBudgetWarningItemModel()).toList(),
    );
  }
}
