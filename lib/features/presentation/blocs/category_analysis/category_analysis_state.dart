part of 'category_analysis_bloc.dart';

abstract class CategoryAnalysisState extends Equatable {
  @override
  List<Object?> get props => [];
}

final class CategoryAnalysisInitial extends CategoryAnalysisState {}

class CategoryAnalysisLoading extends CategoryAnalysisState {}

class CategoryAnalysisRefreshing extends CategoryAnalysisState {
  final CategoryAnalysisModel? analysis;
  final String? type;

  CategoryAnalysisRefreshing(this.analysis, {this.type});

  @override
  List<Object?> get props => [analysis, type];
}

class CategoryAnalysisLoaded extends CategoryAnalysisState {
  final CategoryAnalysisModel? analysis;
  final String? type;

  CategoryAnalysisLoaded(this.analysis, {this.type});

  @override
  List<Object?> get props => [analysis, type];
}

class CategoryAnalysisFailure extends CategoryAnalysisState {
  final String message;

  CategoryAnalysisFailure(this.message);

  @override
  List<Object?> get props => [message];
}
