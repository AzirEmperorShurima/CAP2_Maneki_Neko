part of 'transaction_bloc.dart';

abstract class TransactionState extends Equatable {
  @override
  List<Object?> get props => [];
}

final class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionRefreshing extends TransactionState {
  final List<TransactionModel> transactions;

  TransactionRefreshing(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class TransactionLoaded extends TransactionState {
  final List<TransactionModel> transactions;
  final bool hasMore;
  final int currentPage;
  final String? type;
  final int? limit;
  final DateTime? month;
  final String? walletId;

  TransactionLoaded(
    this.transactions, {
    this.hasMore = true,
    this.currentPage = 1,
    this.type,
    this.limit,
    this.month,
    this.walletId,
  });

  @override
  List<Object?> get props => [transactions, hasMore, currentPage, type, limit, month, walletId];
}

class TransactionLoadingMore extends TransactionState {
  final List<TransactionModel> transactions;
  final int currentPage;

  TransactionLoadingMore(this.transactions, this.currentPage);

  @override
  List<Object?> get props => [transactions, currentPage];
}

class TransactionFailure extends TransactionState {
  final String message;

  TransactionFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class TransactionCreating extends TransactionState {}

class TransactionCreated extends TransactionState {
  final TransactionModel transaction;
  final BudgetWarningModel? budgetWarnings;

  TransactionCreated(this.transaction, {this.budgetWarnings});

  @override
  List<Object?> get props => [transaction, budgetWarnings];
}

class TransactionCreateFailure extends TransactionState {
  final String message;

  TransactionCreateFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class TransactionDeleting extends TransactionState {
  final String transactionId;

  TransactionDeleting(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

class TransactionDeleted extends TransactionState {
  final String transactionId;

  TransactionDeleted(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

class TransactionDeleteFailure extends TransactionState {
  final String message;

  TransactionDeleteFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class TransactionUpdating extends TransactionState {
  final String transactionId;

  TransactionUpdating(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

class TransactionUpdated extends TransactionState {
  final TransactionModel transaction;
  final BudgetWarningModel? budgetWarnings;

  TransactionUpdated(this.transaction, {this.budgetWarnings});

  @override
  List<Object?> get props => [transaction, budgetWarnings];
}

class TransactionUpdateFailure extends TransactionState {
  final String message;

  TransactionUpdateFailure(this.message);

  @override
  List<Object?> get props => [message];
}

