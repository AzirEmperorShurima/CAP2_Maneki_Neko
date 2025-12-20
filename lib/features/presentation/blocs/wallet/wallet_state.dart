part of 'wallet_bloc.dart';

abstract class WalletState extends Equatable {
  @override
  List<Object?> get props => [];
}

final class WalletInitial extends WalletState {}

class WalletLoading extends WalletState {}

class WalletRefreshing extends WalletState {
  final List<WalletModel> wallets;

  WalletRefreshing(this.wallets);

  @override
  List<Object?> get props => [wallets];
}

class WalletLoaded extends WalletState {
  final List<WalletModel> wallets;

  WalletLoaded(this.wallets);

  @override
  List<Object?> get props => [wallets];
}

class WalletFailure extends WalletState {
  final String message;

  WalletFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class WalletCreating extends WalletState {}

class WalletCreated extends WalletState {
  final WalletModel wallet;

  WalletCreated(this.wallet);

  @override
  List<Object?> get props => [wallet];
}

class WalletCreateFailure extends WalletState {
  final String message;

  WalletCreateFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class WalletDeleting extends WalletState {
  final String walletId;

  WalletDeleting(this.walletId);

  @override
  List<Object?> get props => [walletId];
}

class WalletDeleted extends WalletState {
  final String walletId;

  WalletDeleted(this.walletId);

  @override
  List<Object?> get props => [walletId];
}

class WalletDeleteFailure extends WalletState {
  final String message;

  WalletDeleteFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class WalletTransferring extends WalletState {}

class WalletTransferred extends WalletState {}

class WalletTransferFailure extends WalletState {
  final String message;

  WalletTransferFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class WalletUpdating extends WalletState {
  final String walletId;

  WalletUpdating(this.walletId);

  @override
  List<Object?> get props => [walletId];
}

class WalletUpdated extends WalletState {
  final WalletModel wallet;

  WalletUpdated(this.wallet);

  @override
  List<Object?> get props => [wallet];
}

class WalletUpdateFailure extends WalletState {
  final String message;

  WalletUpdateFailure(this.message);

  @override
  List<Object?> get props => [message];
}