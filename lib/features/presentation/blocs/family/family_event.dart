part of 'family_bloc.dart';

sealed class FamilyEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadFamilySubmitted extends FamilyEvent {
  LoadFamilySubmitted();

  @override
  List<Object?> get props => [];
}

class RefreshFamily extends FamilyEvent {
  RefreshFamily();

  @override
  List<Object?> get props => [];
}

class ResetFamily extends FamilyEvent {
  ResetFamily();

  @override
  List<Object?> get props => [];
}

class InviteToFamilySubmitted extends FamilyEvent {
  final String email;

  InviteToFamilySubmitted({required this.email});

  @override
  List<Object?> get props => [email];
}

class JoinFamilySubmitted extends FamilyEvent {
  final String familyCode;

  JoinFamilySubmitted({required this.familyCode});

  @override
  List<Object?> get props => [familyCode];
}

class CreateFamilySubmitted extends FamilyEvent {
  final String name;

  CreateFamilySubmitted({required this.name});

  @override
  List<Object?> get props => [name];
}

class LoadFamilyAnalyticsSummary extends FamilyEvent {
  LoadFamilyAnalyticsSummary();

  @override
  List<Object?> get props => [];
}

class LoadFamilyUserBreakdown extends FamilyEvent {
  LoadFamilyUserBreakdown();

  @override
  List<Object?> get props => [];
}

class LoadFamilyTopCategories extends FamilyEvent {
  LoadFamilyTopCategories();

  @override
  List<Object?> get props => [];
}

class LoadFamilyTopWallets extends FamilyEvent {
  LoadFamilyTopWallets();

  @override
  List<Object?> get props => [];
}
