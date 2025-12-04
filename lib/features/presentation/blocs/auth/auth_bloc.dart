import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finance_management_app/features/presentation/blocs/auth/auth_event.dart';
import 'package:finance_management_app/features/presentation/blocs/auth/auth_state.dart';

import '../../../domain/services/auth_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService service;
  AuthBloc(this.service) : super(const AuthState(status: AuthStatus.unauthenticated)) {
    on<AuthCheckRequested>(_onCheck);
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onCheck(AuthCheckRequested e, Emitter<AuthState> emit) async {
    final ok = await service.isLoggedIn();
    emit(state.copyWith(status: ok ? AuthStatus.authenticated : AuthStatus.unauthenticated));
  }

  Future<void> _onLogout(LogoutRequested e, Emitter<AuthState> emit) async {
    await service.logout();
    emit(state.copyWith(status: AuthStatus.unauthenticated));
  }
}


