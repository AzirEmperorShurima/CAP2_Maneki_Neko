part of 'category_analysis_bloc.dart';

sealed class CategoryAnalysisEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadCategoryAnalysisSubmitted extends CategoryAnalysisEvent {
  final String? type;

  LoadCategoryAnalysisSubmitted({this.type});

  @override
  List<Object?> get props => [type];
}

class RefreshCategoryAnalysis extends CategoryAnalysisEvent {
  final String? type;

  RefreshCategoryAnalysis({this.type});

  @override
  List<Object?> get props => [type];
}

class ResetCategoryAnalysis extends CategoryAnalysisEvent {
  ResetCategoryAnalysis();

  @override
  List<Object?> get props => [];
}
