import '../../data/response/family_analytics_summary_response.dart';
import '../entities/family_analytics_summary_model.dart';
import 'period_translator.dart';

extension FamilyAnalyticsSummaryTranslator on FamilyAnalyticsSummaryResponse {
  FamilyAnalyticsSummaryModel toFamilyAnalyticsSummaryModel() {
    return FamilyAnalyticsSummaryModel(
      period: period?.toPeriodModel(),
      totals: totals?.toFamilyAnalyticsTotalsModel(),
      memberSummary: memberSummary
          ?.map((item) => item.toFamilyMemberSummaryModel())
          .toList(),
    );
  }
}

extension FamilyAnalyticsTotalsTranslator on FamilyAnalyticsTotalsResponse {
  FamilyAnalyticsTotalsModel toFamilyAnalyticsTotalsModel() {
    return FamilyAnalyticsTotalsModel(
      expense: expense,
      income: income,
      balance: balance,
      transactionCount: transactionCount,
    );
  }
}

extension FamilyMemberSummaryTranslator on FamilyMemberSummaryResponse {
  FamilyMemberSummaryModel toFamilyMemberSummaryModel() {
    return FamilyMemberSummaryModel(
      income: income,
      expense: expense,
      incomeCount: incomeCount,
      expenseCount: expenseCount,
      userId: userId,
      username: username,
      email: email,
      avatar: avatar,
      balance: balance,
    );
  }
}
