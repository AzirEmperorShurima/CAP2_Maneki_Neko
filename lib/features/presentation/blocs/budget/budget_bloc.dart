import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:finance_management_app/features/domain/entities/budget_model.dart';
import 'package:finance_management_app/features/domain/repository/budget_repository.dart';
import 'package:injectable/injectable.dart';

import '../../../data/requests/budget_request.dart';

part 'budget_event.dart';
part 'budget_state.dart';

@injectable
class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final BudgetRepository budgetRepository;

  BudgetBloc(this.budgetRepository) : super(BudgetInitial()) {
    on<LoadBudgetsSubmitted>(_onLoadBudgetsSubmitted);
    on<RefreshBudgets>(_onRefreshBudgets);
    on<CreateBudgetSubmitted>(_onCreateBudgetSubmitted);
    on<UpdateBudgetSubmitted>(_onUpdateBudgetSubmitted);
    on<DeleteBudgetSubmitted>(_onDeleteBudgetSubmitted);
    on<ResetBudgets>(_onResetBudgets);
  }

  Future<void> _onLoadBudgetsSubmitted(
    LoadBudgetsSubmitted event,
    Emitter<BudgetState> emit,
  ) async {
    // Kiểm tra xem đã có data chưa (chỉ skip nếu đã có data)
    // Sau khi reset về BudgetInitial, sẽ gọi API lại
    final currentState = state;
    if (currentState is BudgetLoaded && currentState.budgets.isNotEmpty) {
      // Đã có data hợp lệ, không cần gọi API lại
      return;
    }

    emit(BudgetLoading());

    final result = await budgetRepository.getBudgets();

    result.when(
      success: (data) {
        emit(BudgetLoaded(data ?? []));
      },
      failure: (error) {
        emit(BudgetFailure(error));
      },
    );
  }

  void _onResetBudgets(
    ResetBudgets event,
    Emitter<BudgetState> emit,
  ) {
    emit(BudgetInitial());
  }

  Future<void> _onRefreshBudgets(
    RefreshBudgets event,
    Emitter<BudgetState> emit,
  ) async {
    final currentState = state;
    if (currentState is BudgetLoaded) {
      emit(BudgetRefreshing(currentState.budgets));
    } else {
      emit(BudgetLoading());
    }

    final result = await budgetRepository.getBudgets();

    result.when(
      success: (data) {
        emit(BudgetLoaded(data ?? []));
      },
      failure: (error) {
        emit(BudgetFailure(error));
      },
    );
  }

  Future<void> _onCreateBudgetSubmitted(
    CreateBudgetSubmitted event,
    Emitter<BudgetState> emit,
  ) async {
    emit(BudgetCreating());

    final request = BudgetRequest(
      name: event.name,
      type: event.type,
      amount: event.amount,
      updateIfExists: event.updateIfExists,
    );

    final result = await budgetRepository.createBudget(request);

    result.when(
      success: (data) {
        if (data != null) {
          emit(BudgetCreated(data));
        } else {
          emit(BudgetCreateFailure('Không thể tạo ngân sách'));
        }
      },
      failure: (error) {
        emit(BudgetCreateFailure(error));
      },
    );
  }

  Future<void> _onUpdateBudgetSubmitted(
    UpdateBudgetSubmitted event,
    Emitter<BudgetState> emit,
  ) async {
    emit(BudgetUpdating(event.budgetId));

    // Chỉ gửi amount khi update, không gửi name và type
    final request = BudgetRequest(
      amount: event.amount,
    );

    final result = await budgetRepository.updateBudget(event.budgetId, request);

    result.when(
      success: (data) {
        if (data != null) {
          emit(BudgetUpdated(data));
        } else {
          emit(BudgetUpdateFailure('Không thể cập nhật ngân sách'));
        }
      },
      failure: (error) {
        emit(BudgetUpdateFailure(error));
      },
    );
  }

  Future<void> _onDeleteBudgetSubmitted(
    DeleteBudgetSubmitted event,
    Emitter<BudgetState> emit,
  ) async {
    emit(BudgetDeleting(event.budgetId));

    final result = await budgetRepository.deleteBudget(event.budgetId);

    result.when(
      success: (_) {
        emit(BudgetDeleted(event.budgetId));
      },
      failure: (error) {
        emit(BudgetDeleteFailure(error));
      },
    );
  }
}
