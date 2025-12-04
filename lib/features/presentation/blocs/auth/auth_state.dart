import 'package:equatable/equatable.dart';

enum AuthStatus { unknown, unauthenticated, loading, authenticated, failure }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? error,
  }) => AuthState(
    status: status ?? this.status,
    error: error,
  );

  @override
  List<Object?> get props => [status, error];
}


