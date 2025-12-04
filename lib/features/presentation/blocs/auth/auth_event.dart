sealed class AuthEvent {}
class AuthCheckRequested extends AuthEvent {}
class LogoutRequested extends AuthEvent {}