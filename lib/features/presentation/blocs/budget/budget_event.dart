part of 'budget_bloc.dart';

sealed class BudgetEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Lấy danh sách ngân sách
class LoadBudgetsSubmitted extends BudgetEvent {
  LoadBudgetsSubmitted();

  @override
  List<Object?> get props => [];
}

class RefreshBudgets extends BudgetEvent {
  RefreshBudgets();

  @override
  List<Object?> get props => [];
}

// Tạo ngân sách mới
class CreateBudgetSubmitted extends BudgetEvent {
  final String? name;
  final String? type;
  final num? amount;
  final bool? updateIfExists;

  CreateBudgetSubmitted({
    this.name,
    this.type,
    this.amount,
    this.updateIfExists,
  });

  @override
  List<Object?> get props => [name, type, amount, updateIfExists];
}

// Cập nhật ngân sách
class UpdateBudgetSubmitted extends BudgetEvent {
  final String budgetId;
  final String? name;
  final String? type;
  final num? amount;

  UpdateBudgetSubmitted({
    required this.budgetId,
    this.name,
    this.type,
    this.amount,
  });

  @override
  List<Object?> get props => [budgetId, name, type, amount];
}

// Xóa ngân sách
class DeleteBudgetSubmitted extends BudgetEvent {
  final String budgetId;

  DeleteBudgetSubmitted({
    required this.budgetId,
  });

  @override
  List<Object?> get props => [budgetId];
}

// Reset budgets (khi logout)
class ResetBudgets extends BudgetEvent {
  ResetBudgets();

  @override
  List<Object?> get props => [];
}
