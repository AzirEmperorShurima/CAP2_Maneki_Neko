part of 'analysis_bloc.dart';

sealed class AnalysisEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Lấy dữ liệu phân tích
class LoadAnalysisSubmitted extends AnalysisEvent {
  final bool? includePeriodBreakdown;
  final String? breakdownType;
  final String? walletId;
  final DateTime? startDate;
  final DateTime? endDate;

  LoadAnalysisSubmitted({
    this.includePeriodBreakdown,
    this.breakdownType,
    this.walletId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [
        includePeriodBreakdown,
        breakdownType,
        walletId,
        startDate,
        endDate,
      ];
}

class RefreshAnalysis extends AnalysisEvent {
  final bool? includePeriodBreakdown;
  final String? breakdownType;
  final String? walletId;
  final DateTime? startDate;
  final DateTime? endDate;

  RefreshAnalysis({
    this.includePeriodBreakdown,
    this.breakdownType,
    this.walletId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [
        includePeriodBreakdown,
        breakdownType,
        walletId,
        startDate,
        endDate,
      ];
}

class ResetAnalysis extends AnalysisEvent {
  ResetAnalysis();

  @override
  List<Object?> get props => [];
}
