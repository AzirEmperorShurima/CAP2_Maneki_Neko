import '../../data/response/family_user_breakdown_response.dart';
import '../entities/family_user_breakdown_model.dart';
import 'period_translator.dart';

extension FamilyUserBreakdownTranslator on FamilyUserBreakdownResponse {
  FamilyUserBreakdownModel toFamilyUserBreakdownModel() {
    return FamilyUserBreakdownModel(
      period: period?.toPeriodModel(),
      summary: summary?.toFamilyBreakdownSummaryModel(),
      breakdown: breakdown
          ?.map((item) => item.toFamilyBreakdownItemModel())
          .toList(),
      charts: charts?.toFamilyBreakdownChartsModel(),
    );
  }
}

extension FamilyBreakdownSummaryTranslator on FamilyBreakdownSummaryResponse {
  FamilyBreakdownSummaryModel toFamilyBreakdownSummaryModel() {
    return FamilyBreakdownSummaryModel(
      totalExpense: totalExpense,
      totalIncome: totalIncome,
      totalTransactions: totalTransactions,
      memberCount: memberCount,
      familyBalance: familyBalance,
    );
  }
}

extension FamilyBreakdownItemTranslator on FamilyBreakdownItemResponse {
  FamilyBreakdownItemModel toFamilyBreakdownItemModel() {
    return FamilyBreakdownItemModel(
      totalTransactions: totalTransactions,
      userId: userId,
      username: username,
      email: email,
      avatar: avatar,
      expense: expense?.toFamilyBreakdownTransactionModel(),
      income: income?.toFamilyBreakdownTransactionModel(),
      balance: balance,
    );
  }
}

extension FamilyBreakdownTransactionTranslator on FamilyBreakdownTransactionResponse {
  FamilyBreakdownTransactionModel toFamilyBreakdownTransactionModel() {
    return FamilyBreakdownTransactionModel(
      total: total,
      count: count,
    );
  }
}

extension FamilyBreakdownChartsTranslator on FamilyBreakdownChartsResponse {
  FamilyBreakdownChartsModel toFamilyBreakdownChartsModel() {
    return FamilyBreakdownChartsModel(
      expense: expense?.toFamilyBreakdownChartDataModel(),
      income: income?.toFamilyBreakdownChartDataModel(),
    );
  }
}

extension FamilyBreakdownChartDataTranslator on FamilyBreakdownChartDataResponse {
  FamilyBreakdownChartDataModel toFamilyBreakdownChartDataModel() {
    return FamilyBreakdownChartDataModel(
      title: title,
      data: data?.map((item) => item.toFamilyBreakdownChartItemModel()).toList(),
      total: total,
    );
  }
}

extension FamilyBreakdownChartItemTranslator on FamilyBreakdownChartItemResponse {
  FamilyBreakdownChartItemModel toFamilyBreakdownChartItemModel() {
    return FamilyBreakdownChartItemModel(
      name: name,
      value: value,
      percentage: percentage,
      userId: userId,
    );
  }
}
