import 'package:finance_management_app/features/data/requests/budget_request.dart';
import 'package:finance_management_app/features/domain/translator/budget_translator.dart';
import 'package:injectable/injectable.dart';

import '../../../core/common/bases/base_repository.dart';
import '../../../core/network/api_result.dart';
import '../../domain/entities/budget_model.dart';
import '../../domain/repository/budget_repository.dart';
import '../remote/api_client.dart';
import '../response/budget_response.dart';

@LazySingleton(as: BudgetRepository)
class BudgetRepositoryImpl extends BaseRepository implements BudgetRepository {
  final ApiClient apiClient;

  BudgetRepositoryImpl(this.apiClient);

  @override
  Future<ApiResult<List<BudgetModel>?>> getBudgets() {
    return handleApiResponse<List<BudgetModel>?>(
      () async {
        final response = await apiClient.getBudgets();

        final budgetResponses = response.getItems(
          BudgetResponse.fromJson,
          fromKey: 'budgets',
        );

        return budgetResponses
            ?.map((response) => response.toBudgetModel())
            .toList();
      },
    );
  }

  @override
  Future<ApiResult<BudgetModel?>> createBudget(BudgetRequest? request) {
    return handleApiResponse<BudgetModel?>(
      () async {
        final response = await apiClient.createBudget(request);

        final budgetResponse = response.getBody(
          BudgetResponse.fromJson,
          fromKey: 'budget',
        )?.toBudgetModel();

        return budgetResponse;
      },
    );
  }

  @override
  Future<ApiResult<BudgetModel?>> updateBudget(String id, BudgetRequest? request) {
    return handleApiResponse<BudgetModel?>(
      () async {
        final response = await apiClient.updateBudget(id, request);

        final budgetResponse = response.getBody(
          BudgetResponse.fromJson,
          fromKey: 'budget',
        )?.toBudgetModel();

        return budgetResponse;
      },
    );
  }

  @override
  Future<ApiResult<void>> deleteBudget(String id) {
    return handleApiResponse<void>(
      () async {
        final response = await apiClient.deleteBudget(id);
        return response;
      },
    );
  }
}
