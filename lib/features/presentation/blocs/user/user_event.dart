part of 'user_bloc.dart';

sealed class UserEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadUser extends UserEvent {}

class UpdateUser extends UserEvent {
  final UserModel user;

  UpdateUser(this.user);

  @override
  List<Object?> get props => [user];
}
