import 'period_model.dart';

class FamilyAnalyticsSummaryModel {
  final PeriodModel? period;
  final FamilyAnalyticsTotalsModel? totals;
  final List<FamilyMemberSummaryModel>? memberSummary;

  FamilyAnalyticsSummaryModel({
    this.period,
    this.totals,
    this.memberSummary,
  });
}

class FamilyAnalyticsTotalsModel {
  final double? expense;
  final double? income;
  final double? balance;
  final int? transactionCount;

  FamilyAnalyticsTotalsModel({
    this.expense,
    this.income,
    this.balance,
    this.transactionCount,
  });
}

class FamilyMemberSummaryModel {
  final double? income;
  final double? expense;
  final int? incomeCount;
  final int? expenseCount;
  final String? userId;
  final String? username;
  final String? email;
  final String? avatar;
  final double? balance;

  FamilyMemberSummaryModel({
    this.income,
    this.expense,
    this.incomeCount,
    this.expenseCount,
    this.userId,
    this.username,
    this.email,
    this.avatar,
    this.balance,
  });
}
