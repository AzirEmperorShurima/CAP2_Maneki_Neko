part of 'wallet_bloc.dart';

sealed class WalletEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Lấy danh sách ví
class LoadWalletsSubmitted extends WalletEvent {
  LoadWalletsSubmitted();

  @override
  List<Object?> get props => [];
}

class RefreshWallets extends WalletEvent {
  RefreshWallets();

  @override
  List<Object?> get props => [];
}

// Tạo ví mới
class CreateWalletSubmitted extends WalletEvent {
  final String? name;
  final String? type;
  final num? balance;
  final String? description;
  final bool? isDefault;

  CreateWalletSubmitted({
    this.name,
    this.type,
    this.balance,
    this.description,
    this.isDefault,
  });

  @override
  List<Object?> get props => [name, type, balance, description, isDefault];
}

// Cập nhật ví
class UpdateWalletSubmitted extends WalletEvent {
  final String walletId;
  final String? name;
  final String? type;
  final num? balance;
  final String? description;
  final bool? isDefault;

  UpdateWalletSubmitted({
    required this.walletId,
    this.name,
    this.type,
    this.balance,
    this.description,
    this.isDefault,
  });

  @override
  List<Object?> get props => [walletId, name, type, balance, description, isDefault];
}

// Xóa ví
class DeleteWalletSubmitted extends WalletEvent {
  final String walletId;

  DeleteWalletSubmitted({
    required this.walletId,
  });

  @override
  List<Object?> get props => [walletId];
}

// Reset wallets (khi logout)
class ResetWallets extends WalletEvent {
  ResetWallets();

  @override
  List<Object?> get props => [];
}

// Chuyển tiền giữa các ví
class TransferWalletSubmitted extends WalletEvent {
  final String? fromWalletId;
  final String? toWalletId;
  final num? amount;
  final String? note;

  TransferWalletSubmitted({
    this.fromWalletId,
    this.toWalletId,
    this.amount,
    this.note,
  });

  @override
  List<Object?> get props => [fromWalletId, toWalletId, amount, note];
}