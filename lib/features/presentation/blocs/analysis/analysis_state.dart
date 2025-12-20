part of 'analysis_bloc.dart';

abstract class AnalysisState extends Equatable {
  @override
  List<Object?> get props => [];
}

final class AnalysisInitial extends AnalysisState {}

class AnalysisLoading extends AnalysisState {}

class AnalysisRefreshing extends AnalysisState {
  final AnalysisModel? analysis;

  AnalysisRefreshing(this.analysis);

  @override
  List<Object?> get props => [analysis];
}

class AnalysisLoaded extends AnalysisState {
  final AnalysisModel? analysis;
  final DateTime? startDate;
  final DateTime? endDate;

  AnalysisLoaded(this.analysis, {this.startDate, this.endDate});

  @override
  List<Object?> get props => [analysis, startDate, endDate];
}

class AnalysisFailure extends AnalysisState {
  final String message;

  AnalysisFailure(this.message);

  @override
  List<Object?> get props => [message];
}
