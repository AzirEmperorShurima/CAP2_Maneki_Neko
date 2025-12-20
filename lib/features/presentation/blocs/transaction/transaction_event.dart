part of 'transaction_bloc.dart';

sealed class TransactionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Lấy danh sách giao dịch
class LoadTransactionsSubmitted extends TransactionEvent {
  final String? type;
  final int? page;
  final int? limit;
  final DateTime? month;
  final String? walletId;

  LoadTransactionsSubmitted({
    this.type,
    this.page,
    this.limit,
    this.month,
    this.walletId,
  });

  @override
  List<Object?> get props => [type, page, limit, month, walletId];
}

// Refresh danh sách giao dịch
class RefreshTransactions extends TransactionEvent {
  final String? type;
  final int? page;
  final int? limit;
  final DateTime? month;
  final String? walletId;

  RefreshTransactions({
    this.type,
    this.page,
    this.limit,
    this.month,
    this.walletId,
  });

  @override
  List<Object?> get props => [type, page, limit, month, walletId];
}

// Load thêm giao dịch
class LoadMoreTransactions extends TransactionEvent {
  final String? type;
  final int? page;
  final int? limit;
  final DateTime? month;
  final String? walletId;

  LoadMoreTransactions({
    this.type,
    this.page,
    this.limit,
    this.month,
    this.walletId,
  });

  @override
  List<Object?> get props => [type, page, limit, month, walletId];
}

// Tạo giao dịch mới
class CreateTransactionSubmitted extends TransactionEvent {
  final String? type;
  final num? amount;
  final String? description;
  final String? categoryId;
  final DateTime? date;
  final String? walletId;
  final String? memberType;

  CreateTransactionSubmitted({
    this.type,
    this.amount,
    this.description,
    this.categoryId,
    this.date,
    this.walletId,
    this.memberType,
  });

  @override
  List<Object?> get props => [type, amount, description, categoryId, date, walletId, memberType];
}

// Cập nhật giao dịch
class UpdateTransactionSubmitted extends TransactionEvent {
  final String transactionId;
  final String? type;
  final num? amount;
  final String? description;
  final String? categoryId;
  final DateTime? date;
  final String? walletId;
  final String? memberType;

  UpdateTransactionSubmitted({
    required this.transactionId,
    this.type,
    this.amount,
    this.description,
    this.categoryId,
    this.date,
    this.walletId,
    this.memberType,
  });

  @override
  List<Object?> get props => [transactionId, type, amount, description, categoryId, date, walletId, memberType];
}

// Xóa giao dịch
class DeleteTransactionSubmitted extends TransactionEvent {
  final String transactionId;

  DeleteTransactionSubmitted({
    required this.transactionId,
  });

  @override
  List<Object?> get props => [transactionId];
}

// Reset transactions (khi logout)
class ResetTransactions extends TransactionEvent {
  ResetTransactions();

  @override
  List<Object?> get props => [];
}
