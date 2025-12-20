part of 'wallet_analysis_bloc.dart';

sealed class WalletAnalysisEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadWalletAnalysisSubmitted extends WalletAnalysisEvent {
  final String walletId;

  LoadWalletAnalysisSubmitted({required this.walletId});

  @override
  List<Object?> get props => [walletId];
}

class RefreshWalletAnalysis extends WalletAnalysisEvent {
  final String walletId;

  RefreshWalletAnalysis({required this.walletId});

  @override
  List<Object?> get props => [walletId];
}

class ResetWalletAnalysis extends WalletAnalysisEvent {
  ResetWalletAnalysis();

  @override
  List<Object?> get props => [];
}
