part of 'wallet_analysis_bloc.dart';

abstract class WalletAnalysisState extends Equatable {
  @override
  List<Object?> get props => [];
}

final class WalletAnalysisInitial extends WalletAnalysisState {}

class WalletAnalysisLoading extends WalletAnalysisState {}

class WalletAnalysisRefreshing extends WalletAnalysisState {
  final WalletAnalysisModel? analysis;
  final String? walletId;

  WalletAnalysisRefreshing(this.analysis, {this.walletId});

  @override
  List<Object?> get props => [analysis, walletId];
}

class WalletAnalysisLoaded extends WalletAnalysisState {
  final WalletAnalysisModel? analysis;
  final String? walletId;

  WalletAnalysisLoaded(this.analysis, {this.walletId});

  @override
  List<Object?> get props => [analysis, walletId];
}

class WalletAnalysisFailure extends WalletAnalysisState {
  final String message;

  WalletAnalysisFailure(this.message);

  @override
  List<Object?> get props => [message];
}
