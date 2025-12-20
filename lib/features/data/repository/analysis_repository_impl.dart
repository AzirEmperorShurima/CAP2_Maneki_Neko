import 'package:finance_management_app/features/domain/repository/analysis_repository.dart';
import 'package:finance_management_app/features/domain/translator/analysis_translator.dart';
import 'package:finance_management_app/features/domain/translator/category_analysis_translator.dart';
import 'package:finance_management_app/features/domain/translator/wallet_analysis_translator.dart';
import 'package:injectable/injectable.dart';

import '../../../core/common/bases/base_repository.dart';
import '../../../core/network/api_result.dart';
import '../../domain/entities/analysis_model.dart';
import '../../domain/entities/category_analysis_model.dart';
import '../../domain/entities/wallet_analysis_model.dart';
import '../remote/api_client.dart';
import '../response/analysis_response.dart';
import '../response/category_analysis_response.dart';
import '../response/wallet_analysis_response.dart';

@LazySingleton(as: AnalysisRepository)
class AnalysisRepositoryImpl extends BaseRepository
    implements AnalysisRepository {
  final ApiClient apiClient;

  AnalysisRepositoryImpl(this.apiClient);

  @override
  Future<ApiResult<AnalysisModel?>> getPersonalOverview(
    bool? includePeriodBreakdown,
    String? breakdownType,
    String? walletId,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    return handleApiResponse<AnalysisModel?>(
      () async {
        final response = await apiClient.getPersonalOverview(
          includePeriodBreakdown,
          breakdownType,
          walletId,
          startDate,
          endDate,
        );

        final analysisResponse = response
            .getBody(AnalysisResponse.fromJson)
            ?.toAnalysisModel();

        return analysisResponse;
      },
    );
  }

  @override
  Future<ApiResult<WalletAnalysisModel?>> getWalletAnalysis(String walletId) {
    return handleApiResponse<WalletAnalysisModel?>(
      () async {
        final response = await apiClient.getWalletAnalysis(walletId);

        final walletAnalysisResponse = response
            .getBody(WalletAnalysisResponse.fromJson)
            ?.toWalletAnalysisModel();

        return walletAnalysisResponse;
      },
    );
  }

  @override
  Future<ApiResult<CategoryAnalysisModel?>> getAnalysisByCategory(String? type) {
    return handleApiResponse<CategoryAnalysisModel?>(
      () async {
        final response = await apiClient.getAnalysisCategories(type);

        final categoryAnalysisResponse = response
            .getBody(CategoryAnalysisResponse.fromJson)
            ?.toCategoryAnalysisModel();

        return categoryAnalysisResponse;
      },
    );
  }
}
