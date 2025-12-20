import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:finance_management_app/features/domain/entities/analysis_model.dart';
import 'package:finance_management_app/features/domain/repository/analysis_repository.dart';
import 'package:injectable/injectable.dart';

part 'analysis_event.dart';
part 'analysis_state.dart';

@injectable
class AnalysisBloc extends Bloc<AnalysisEvent, AnalysisState> {
  final AnalysisRepository analysisRepository;

  AnalysisBloc(this.analysisRepository) : super(AnalysisInitial()) {
    on<LoadAnalysisSubmitted>(_onLoadAnalysisSubmitted);
    on<RefreshAnalysis>(_onRefreshAnalysis);
    on<ResetAnalysis>(_onResetAnalysis);
  }

  Future<void> _onLoadAnalysisSubmitted(
    LoadAnalysisSubmitted event,
    Emitter<AnalysisState> emit,
  ) async {
    final currentState = state;
    
    // Kiểm tra nếu đã có data và params giống hệt thì skip
    if (currentState is AnalysisLoaded) {
      
      final paramsMatch = _compareDates(currentState.startDate, event.startDate) &&
          _compareDates(currentState.endDate, event.endDate);
      
      if (paramsMatch && currentState.analysis != null) {
      return;
      }
    }

    emit(AnalysisLoading());

    final result = await analysisRepository.getPersonalOverview(
      event.includePeriodBreakdown,
      event.breakdownType,
      event.walletId,
      event.startDate,
      event.endDate,
    );

    result.when(
      success: (data) {
        emit(AnalysisLoaded(data, startDate: event.startDate, endDate: event.endDate));
      },
      failure: (error) {
        emit(AnalysisFailure(error));
      },
    );
  }

  bool _compareDates(DateTime? date1, DateTime? date2) {
    if (date1 == null && date2 == null) return true;
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  void _onResetAnalysis(
    ResetAnalysis event,
    Emitter<AnalysisState> emit,
  ) {
    emit(AnalysisInitial());
  }

  Future<void> _onRefreshAnalysis(
    RefreshAnalysis event,
    Emitter<AnalysisState> emit,
  ) async {
    final currentState = state;
    if (currentState is AnalysisLoaded) {
      emit(AnalysisRefreshing(currentState.analysis));
    } else {
      emit(AnalysisLoading());
    }

    final result = await analysisRepository.getPersonalOverview(
      event.includePeriodBreakdown,
      event.breakdownType,
      event.walletId,
      event.startDate,
      event.endDate,
    );

    result.when(
      success: (data) {
        emit(AnalysisLoaded(data, startDate: event.startDate, endDate: event.endDate));
      },
      failure: (error) {
        if (currentState is AnalysisLoaded) {
          emit(AnalysisLoaded(currentState.analysis, startDate: currentState.startDate, endDate: currentState.endDate));
        } else {
          emit(AnalysisFailure(error));
        }
      },
    );
  }
}
