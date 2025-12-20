part of 'budget_bloc.dart';

abstract class BudgetState extends Equatable {
  @override
  List<Object?> get props => [];
}

final class BudgetInitial extends BudgetState {}

class BudgetLoading extends BudgetState {}

class BudgetRefreshing extends BudgetState {
  final List<BudgetModel> budgets;

  BudgetRefreshing(this.budgets);

  @override
  List<Object?> get props => [budgets];
}

class BudgetLoaded extends BudgetState {
  final List<BudgetModel> budgets;

  BudgetLoaded(this.budgets);

  @override
  List<Object?> get props => [budgets];
}

class BudgetFailure extends BudgetState {
  final String message;

  BudgetFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class BudgetCreating extends BudgetState {}

class BudgetCreated extends BudgetState {
  final BudgetModel budget;

  BudgetCreated(this.budget);

  @override
  List<Object?> get props => [budget];
}

class BudgetCreateFailure extends BudgetState {
  final String message;

  BudgetCreateFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class BudgetUpdating extends BudgetState {
  final String budgetId;

  BudgetUpdating(this.budgetId);

  @override
  List<Object?> get props => [budgetId];
}

class BudgetUpdated extends BudgetState {
  final BudgetModel budget;

  BudgetUpdated(this.budget);

  @override
  List<Object?> get props => [budget];
}

class BudgetUpdateFailure extends BudgetState {
  final String message;

  BudgetUpdateFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class BudgetDeleting extends BudgetState {
  final String budgetId;

  BudgetDeleting(this.budgetId);

  @override
  List<Object?> get props => [budgetId];
}

class BudgetDeleted extends BudgetState {
  final String budgetId;

  BudgetDeleted(this.budgetId);

  @override
  List<Object?> get props => [budgetId];
}

class BudgetDeleteFailure extends BudgetState {
  final String message;

  BudgetDeleteFailure(this.message);

  @override
  List<Object?> get props => [message];
}
