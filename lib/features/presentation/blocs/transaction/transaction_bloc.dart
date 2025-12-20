import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:finance_management_app/features/data/requests/transaction_request.dart';
import 'package:finance_management_app/features/domain/entities/budget_warning_model.dart';
import 'package:finance_management_app/features/domain/entities/transaction_model.dart';
import 'package:finance_management_app/features/domain/repository/transaction_repository.dart';
import 'package:injectable/injectable.dart';

part 'transaction_event.dart';
part 'transaction_state.dart';

@injectable
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository transactionRepository;

  TransactionBloc(this.transactionRepository) : super(TransactionInitial()) {
    on<LoadTransactionsSubmitted>(_onLoadTransactionsSubmitted);
    on<RefreshTransactions>(_onRefreshTransactions);
    on<LoadMoreTransactions>(_onLoadMoreTransactions);
    on<CreateTransactionSubmitted>(_onCreateTransactionSubmitted);
    on<UpdateTransactionSubmitted>(_onUpdateTransactionSubmitted);
    on<DeleteTransactionSubmitted>(_onDeleteTransactionSubmitted);
    on<ResetTransactions>(_onResetTransactions);
  }

  Future<void> _onLoadTransactionsSubmitted(
    LoadTransactionsSubmitted event,
    Emitter<TransactionState> emit,
  ) async {
    final currentState = state;
    
    // Kiểm tra nếu đã có data và params giống hệt thì skip
    if (currentState is TransactionLoaded) {
      
      final paramsMatch = currentState.type == event.type &&
          currentState.limit == event.limit &&
          _compareDates(currentState.month, event.month) &&
          currentState.walletId == event.walletId &&
          currentState.currentPage == (event.page ?? 1);
      
      if (paramsMatch && currentState.transactions.isNotEmpty) {
        return;
      }
    }

    emit(TransactionLoading());

    final result = await transactionRepository.getTransactions(
      event.type,
      event.page,
      event.limit,
      event.month,
      event.walletId,
    );

    result.when(
      success: (data) {
        final transactions = data ?? [];
        // Giả sử có more nếu số lượng = limit (có thể cải thiện sau với pagination metadata)
        final hasMore = transactions.length >= (event.limit ?? 20);
        emit(TransactionLoaded(
          transactions,
          hasMore: hasMore,
          currentPage: event.page ?? 1,
          type: event.type,
          limit: event.limit,
          month: event.month,
          walletId: event.walletId,
        ));
      },
      failure: (error) {
        emit(TransactionFailure(error));
      },
    );
  }

  bool _compareDates(DateTime? date1, DateTime? date2) {
    if (date1 == null && date2 == null) return true;
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  void _onResetTransactions(
    ResetTransactions event,
    Emitter<TransactionState> emit,
  ) {
    emit(TransactionInitial());
  }

  Future<void> _onLoadMoreTransactions(
    LoadMoreTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TransactionLoaded) return;
    if (!currentState.hasMore) return;

    // Emit loading more state
    emit(TransactionLoadingMore(currentState.transactions, currentState.currentPage));

    final result = await transactionRepository.getTransactions(
      event.type,
      event.page,
      event.limit,
      event.month,
      event.walletId,
    );

    result.when(
      success: (data) {
        final newTransactions = data ?? [];
        final allTransactions = [...currentState.transactions, ...newTransactions];
        // Giả sử có more nếu số lượng = limit
        final hasMore = newTransactions.length >= (event.limit ?? 20);
        emit(TransactionLoaded(
          allTransactions,
          hasMore: hasMore,
          currentPage: event.page ?? 1,
          type: event.type,
          limit: event.limit,
          month: event.month,
          walletId: event.walletId,
        ));
      },
      failure: (error) {
        // Restore previous state on error
        emit(TransactionLoaded(
          currentState.transactions,
          hasMore: currentState.hasMore,
          currentPage: currentState.currentPage,
          type: currentState.type,
          limit: currentState.limit,
          month: currentState.month,
          walletId: currentState.walletId,
        ));
      },
    );
  }

  Future<void> _onRefreshTransactions(
    RefreshTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    // Giữ nguyên state hiện tại nếu đang loading
    if (state is TransactionLoading) return;

    final currentState = state;
    if (currentState is TransactionLoaded) {
      // Giữ data cũ trong khi refresh
      emit(TransactionRefreshing(currentState.transactions));
    } else {
      emit(TransactionLoading());
    }

    final result = await transactionRepository.getTransactions(
      event.type,
      event.page,
      event.limit,
      event.month,
      event.walletId,
    );

    result.when(
      success: (data) {
        final transactions = data ?? [];
        final hasMore = transactions.length >= (event.limit ?? 20);
        emit(TransactionLoaded(
          transactions,
          hasMore: hasMore,
          currentPage: event.page ?? 1,
          type: event.type,
          limit: event.limit,
          month: event.month,
          walletId: event.walletId,
        ));
      },
      failure: (error) {
        // Nếu có data cũ, restore lại
        if (currentState is TransactionLoaded) {
          emit(TransactionLoaded(
            currentState.transactions,
            hasMore: currentState.hasMore,
            currentPage: currentState.currentPage,
            type: currentState.type,
            limit: currentState.limit,
            month: currentState.month,
            walletId: currentState.walletId,
          ));
        } else {
          emit(TransactionFailure(error));
        }
      },
    );
  }

  Future<void> _onCreateTransactionSubmitted(
    CreateTransactionSubmitted event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionCreating());

    final request = TransactionRequest(
      type: event.type,
      amount: event.amount,
      description: event.description,
      categoryId: event.categoryId,
      date: event.date,
      walletId: event.walletId,
      memberType: event.memberType,
    );

    final result = await transactionRepository.createTransaction(request);

    result.when(
      success: (data) {
        if (data != null && data.transaction != null) {
          emit(TransactionCreated(
            data.transaction!,
            budgetWarnings: data.budgetWarnings,
          ));
        } else {
          emit(TransactionFailure('Không thể tạo giao dịch'));
        }
      },
      failure: (error) {
        emit(TransactionFailure(error));
      },
    );
  }

  Future<void> _onUpdateTransactionSubmitted(
    UpdateTransactionSubmitted event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionUpdating(event.transactionId));

    final request = TransactionRequest(
      type: event.type,
      amount: event.amount,
      description: event.description,
      categoryId: event.categoryId,
      date: event.date,
      walletId: event.walletId,
      memberType: event.memberType,
    );

    final result = await transactionRepository.updateTransaction(
      event.transactionId,
      request,
    );

    result.when(
      success: (data) {
        if (data != null && data.transaction != null) {
          emit(TransactionUpdated(
            data.transaction!,
            budgetWarnings: data.budgetWarnings,
          ));
        } else {
          emit(TransactionUpdateFailure('Không thể cập nhật giao dịch'));
        }
      },
      failure: (error) {
        emit(TransactionUpdateFailure(error));
      },
    );
  }

  Future<void> _onDeleteTransactionSubmitted(
    DeleteTransactionSubmitted event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionDeleting(event.transactionId));

    final result = await transactionRepository.deleteTransaction(event.transactionId);

    result.when(
      success: (_) {
        emit(TransactionDeleted(event.transactionId));
      },
      failure: (error) {
        emit(TransactionDeleteFailure(error));
      },
    );
  }
}

