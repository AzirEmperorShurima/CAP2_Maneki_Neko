import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:finance_management_app/features/domain/entities/wallet_analysis_model.dart';
import 'package:finance_management_app/features/domain/repository/analysis_repository.dart';
import 'package:injectable/injectable.dart';

part 'wallet_analysis_event.dart';
part 'wallet_analysis_state.dart';

@injectable
class WalletAnalysisBloc extends Bloc<WalletAnalysisEvent, WalletAnalysisState> {
  final AnalysisRepository analysisRepository;

  WalletAnalysisBloc(this.analysisRepository) : super(WalletAnalysisInitial()) {
    on<LoadWalletAnalysisSubmitted>(_onLoadWalletAnalysisSubmitted);
    on<RefreshWalletAnalysis>(_onRefreshWalletAnalysis);
    on<ResetWalletAnalysis>(_onResetWalletAnalysis);
  }

  Future<void> _onLoadWalletAnalysisSubmitted(
    LoadWalletAnalysisSubmitted event,
    Emitter<WalletAnalysisState> emit,
  ) async {
    // Kiểm tra nếu đang loading hoặc đã có data cùng walletId thì không load lại
    final currentState = state;
    if (currentState is WalletAnalysisLoading) {
      // Đang loading rồi, không load lại
      return;
    }
    
    if (currentState is WalletAnalysisLoaded && 
        currentState.walletId == event.walletId &&
        currentState.analysis != null) {
      // Đã có data cùng walletId, không cần load lại
      return;
    }

    emit(WalletAnalysisLoading());

    final result = await analysisRepository.getWalletAnalysis(event.walletId);

    result.when(
      success: (data) {
        emit(WalletAnalysisLoaded(data, walletId: event.walletId));
      },
      failure: (error) {
        emit(WalletAnalysisFailure(error));
      },
    );
  }

  Future<void> _onRefreshWalletAnalysis(
    RefreshWalletAnalysis event,
    Emitter<WalletAnalysisState> emit,
  ) async {
    final currentState = state;
    if (currentState is WalletAnalysisLoaded) {
      emit(WalletAnalysisRefreshing(currentState.analysis, walletId: currentState.walletId));
    } else {
      emit(WalletAnalysisLoading());
    }

    final result = await analysisRepository.getWalletAnalysis(event.walletId);

    result.when(
      success: (data) {
        emit(WalletAnalysisLoaded(data, walletId: event.walletId));
      },
      failure: (error) {
        if (currentState is WalletAnalysisLoaded) {
          emit(WalletAnalysisLoaded(currentState.analysis, walletId: currentState.walletId));
        } else {
          emit(WalletAnalysisFailure(error));
        }
      },
    );
  }

  void _onResetWalletAnalysis(
    ResetWalletAnalysis event,
    Emitter<WalletAnalysisState> emit,
  ) {
    emit(WalletAnalysisInitial());
  }
}
