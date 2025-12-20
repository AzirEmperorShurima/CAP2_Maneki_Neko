part of 'settings_bloc.dart';

abstract class SettingsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsSuccess extends SettingsState {}

class SettingsFailure extends SettingsState {
  final String message;
  SettingsFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// Logout 
class SettingsLogoutLoading extends SettingsState {}

class SettingsLogoutSuccess extends SettingsState {}

class SettingsLogoutFailure extends SettingsState {
  final String message;
  SettingsLogoutFailure(this.message);

  @override
  List<Object?> get props => [message];
}