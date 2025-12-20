import '../../../core/network/api_result.dart';
import '../entities/analysis_model.dart';
import '../entities/category_analysis_model.dart';
import '../entities/wallet_analysis_model.dart';

abstract class AnalysisRepository {
  Future<ApiResult<AnalysisModel?>> getPersonalOverview(
    bool? includePeriodBreakdown,
    String? breakdownType,
    String? walletId,
    DateTime? startDate,
    DateTime? endDate,
  );

  Future<ApiResult<WalletAnalysisModel?>> getWalletAnalysis(String walletId);

  Future<ApiResult<CategoryAnalysisModel?>> getAnalysisByCategory(String? type);
}
