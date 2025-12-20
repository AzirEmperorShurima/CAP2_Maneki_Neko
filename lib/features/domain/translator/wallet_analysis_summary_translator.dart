import '../../data/response/wallet_analysis_summary_response.dart';
import '../entities/wallet_analysis_summary_model.dart';

extension WalletAnalysisSummaryTranslator on WalletAnalysisSummaryResponse {
  WalletAnalysisSummaryModel toWalletAnalysisSummaryModel() {
    return WalletAnalysisSummaryModel(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      incomeCount: incomeCount,
      expenseCount: expenseCount,
      net: net,
    );
  }
}
