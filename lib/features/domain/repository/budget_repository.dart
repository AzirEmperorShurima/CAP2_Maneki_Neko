import 'package:finance_management_app/core/network/api_result.dart';
import 'package:finance_management_app/features/domain/entities/budget_model.dart';

import '../../data/requests/budget_request.dart';

abstract class BudgetRepository {
  Future<ApiResult<List<BudgetModel>?>> getBudgets();

  Future<ApiResult<BudgetModel?>> createBudget(BudgetRequest? request);

  Future<ApiResult<BudgetModel?>> updateBudget(String id, BudgetRequest? request);

  Future<ApiResult<void>> deleteBudget(String id);
}
