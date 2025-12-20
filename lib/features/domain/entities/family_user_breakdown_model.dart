import 'period_model.dart';

class FamilyUserBreakdownModel {
  final PeriodModel? period;
  final FamilyBreakdownSummaryModel? summary;
  final List<FamilyBreakdownItemModel>? breakdown;
  final FamilyBreakdownChartsModel? charts;

  FamilyUserBreakdownModel({
    this.period,
    this.summary,
    this.breakdown,
    this.charts,
  });
}

class FamilyBreakdownSummaryModel {
  final double? totalExpense;
  final double? totalIncome;
  final int? totalTransactions;
  final int? memberCount;
  final double? familyBalance;

  FamilyBreakdownSummaryModel({
    this.totalExpense,
    this.totalIncome,
    this.totalTransactions,
    this.memberCount,
    this.familyBalance,
  });
}

class FamilyBreakdownItemModel {
  final int? totalTransactions;
  final String? userId;
  final String? username;
  final String? email;
  final String? avatar;
  final FamilyBreakdownTransactionModel? expense;
  final FamilyBreakdownTransactionModel? income;
  final double? balance;

  FamilyBreakdownItemModel({
    this.totalTransactions,
    this.userId,
    this.username,
    this.email,
    this.avatar,
    this.expense,
    this.income,
    this.balance,
  });
}

class FamilyBreakdownTransactionModel {
  final double? total;
  final int? count;

  FamilyBreakdownTransactionModel({
    this.total,
    this.count,
  });
}

class FamilyBreakdownChartsModel {
  final FamilyBreakdownChartDataModel? expense;
  final FamilyBreakdownChartDataModel? income;

  FamilyBreakdownChartsModel({
    this.expense,
    this.income,
  });
}

class FamilyBreakdownChartDataModel {
  final String? title;
  final List<FamilyBreakdownChartItemModel>? data;
  final double? total;

  FamilyBreakdownChartDataModel({
    this.title,
    this.data,
    this.total,
  });
}

class FamilyBreakdownChartItemModel {
  final String? name;
  final double? value;
  final double? percentage;
  final String? userId;

  FamilyBreakdownChartItemModel({
    this.name,
    this.value,
    this.percentage,
    this.userId,
  });
}
