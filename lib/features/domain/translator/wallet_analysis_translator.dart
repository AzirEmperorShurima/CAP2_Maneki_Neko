import '../../data/response/wallet_analysis_response.dart';
import '../entities/wallet_analysis_model.dart';
import 'daily_trend_translator.dart';
import 'expense_by_category_translator.dart';
import 'wallet_analysis_summary_translator.dart';
import 'wallet_summary_translator.dart';

extension WalletAnalysisTranslator on WalletAnalysisResponse {
  WalletAnalysisModel toWalletAnalysisModel() {
    return WalletAnalysisModel(
      wallet: wallet?.toWalletSummaryModel(),
      summary: summary?.toWalletAnalysisSummaryModel(),
      expenseByCategory: expenseByCategory
          ?.map((e) => e.toExpenseByCategoryModel())
          .toList(),
      incomeByCategory: incomeByCategory
          ?.map((e) => e.toExpenseByCategoryModel())
          .toList(),
      dailyTrend: dailyTrend?.map((e) => e.toDailyTrendModel()).toList(),
    );
  }
}
