import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:finance_management_app/features/domain/entities/category_analysis_model.dart';
import 'package:finance_management_app/features/domain/repository/analysis_repository.dart';
import 'package:injectable/injectable.dart';

part 'category_analysis_event.dart';
part 'category_analysis_state.dart';

@injectable
class CategoryAnalysisBloc extends Bloc<CategoryAnalysisEvent, CategoryAnalysisState> {
  final AnalysisRepository analysisRepository;

  CategoryAnalysisBloc(this.analysisRepository) : super(CategoryAnalysisInitial()) {
    on<LoadCategoryAnalysisSubmitted>(_onLoadCategoryAnalysisSubmitted);
    on<RefreshCategoryAnalysis>(_onRefreshCategoryAnalysis);
    on<ResetCategoryAnalysis>(_onResetCategoryAnalysis);
  }

  Future<void> _onLoadCategoryAnalysisSubmitted(
    LoadCategoryAnalysisSubmitted event,
    Emitter<CategoryAnalysisState> emit,
  ) async {
    final currentState = state;
    
    // Kiểm tra nếu đã có data và type giống thì skip
    if (currentState is CategoryAnalysisLoaded) {
      if (currentState.type == event.type && currentState.analysis != null) {
        return;
      }
    }

    emit(CategoryAnalysisLoading());

    final result = await analysisRepository.getAnalysisByCategory(event.type);

    result.when(
      success: (data) {
        emit(CategoryAnalysisLoaded(data, type: event.type));
      },
      failure: (error) {
        emit(CategoryAnalysisFailure(error));
      },
    );
  }

  void _onResetCategoryAnalysis(
    ResetCategoryAnalysis event,
    Emitter<CategoryAnalysisState> emit,
  ) {
    emit(CategoryAnalysisInitial());
  }

  Future<void> _onRefreshCategoryAnalysis(
    RefreshCategoryAnalysis event,
    Emitter<CategoryAnalysisState> emit,
  ) async {
    final currentState = state;
    
    emit(CategoryAnalysisRefreshing(
      currentState is CategoryAnalysisLoaded ? currentState.analysis : null,
      type: event.type,
    ));

    final result = await analysisRepository.getAnalysisByCategory(event.type);

    result.when(
      success: (data) {
        emit(CategoryAnalysisLoaded(data, type: event.type));
      },
      failure: (error) {
        emit(CategoryAnalysisFailure(error));
      },
    );
  }
}
