part of 'family_bloc.dart';

abstract class FamilyState extends Equatable {
  @override
  List<Object?> get props => [];
}

final class FamilyInitial extends FamilyState {}

class FamilyLoading extends FamilyState {}

class FamilyRefreshing extends FamilyState {
  final FamilyModel? family;

  FamilyRefreshing(this.family);

  @override
  List<Object?> get props => [family];
}

class FamilyLoaded extends FamilyState {
  final FamilyModel? family;

  FamilyLoaded(this.family);

  @override
  List<Object?> get props => [family];
}

class FamilyFailure extends FamilyState {
  final String message;

  FamilyFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class FamilyInviting extends FamilyState {}

class FamilyInvited extends FamilyState {
  final String email;
  final FamilyInviteModel? inviteData;

  FamilyInvited(this.email, {this.inviteData});

  @override
  List<Object?> get props => [email, inviteData];
}

class FamilyInviteFailure extends FamilyState {
  final String message;

  FamilyInviteFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class FamilyJoining extends FamilyState {}

class FamilyJoined extends FamilyState {
  final String familyCode;
  final FamilyJoinModel? joinData;

  FamilyJoined(this.familyCode, {this.joinData});

  @override
  List<Object?> get props => [familyCode, joinData];
}

class FamilyJoinFailure extends FamilyState {
  final String message;

  FamilyJoinFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class FamilyCreating extends FamilyState {}

class FamilyCreated extends FamilyState {
  final FamilyModel family;

  FamilyCreated(this.family);

  @override
  List<Object?> get props => [family];
}

class FamilyCreateFailure extends FamilyState {
  final String message;

  FamilyCreateFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class FamilyAnalyticsSummaryLoading extends FamilyState {}

class FamilyAnalyticsSummaryLoaded extends FamilyState {
  final FamilyAnalyticsSummaryModel? summary;

  FamilyAnalyticsSummaryLoaded(this.summary);

  @override
  List<Object?> get props => [summary];
}

class FamilyAnalyticsSummaryFailure extends FamilyState {
  final String message;

  FamilyAnalyticsSummaryFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class FamilyUserBreakdownLoading extends FamilyState {}

class FamilyUserBreakdownLoaded extends FamilyState {
  final FamilyUserBreakdownModel? breakdown;

  FamilyUserBreakdownLoaded(this.breakdown);

  @override
  List<Object?> get props => [breakdown];
}

class FamilyUserBreakdownFailure extends FamilyState {
  final String message;

  FamilyUserBreakdownFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class FamilyTopCategoriesLoading extends FamilyState {}

class FamilyTopCategoriesLoaded extends FamilyState {
  final FamilyTopCategoriesModel? categories;

  FamilyTopCategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class FamilyTopCategoriesFailure extends FamilyState {
  final String message;

  FamilyTopCategoriesFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class FamilyTopWalletsLoading extends FamilyState {}

class FamilyTopWalletsLoaded extends FamilyState {
  final FamilyTopWalletsModel? topWallets;

  FamilyTopWalletsLoaded(this.topWallets);

  @override
  List<Object?> get props => [topWallets];
}

class FamilyTopWalletsFailure extends FamilyState {
  final String message;

  FamilyTopWalletsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
