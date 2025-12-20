import 'package:equatable/equatable.dart';

abstract class LoginState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {}

// Login with email
class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {}

class LoginFailure extends LoginState {
  final String message;
  LoginFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// Login with Google
class LoginWithGoogleLoading extends LoginState {}

class LoginWithGoogleSuccess extends LoginState {}

class LoginWithGoogleFailure extends LoginState {
  final String message;
  LoginWithGoogleFailure(this.message);

  @override
  List<Object?> get props => [message];
}
