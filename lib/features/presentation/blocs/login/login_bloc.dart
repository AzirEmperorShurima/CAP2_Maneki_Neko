import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finance_management_app/features/presentation/blocs/login/login_event.dart';
import 'package:finance_management_app/features/presentation/blocs/login/login_state.dart';
import 'package:finance_management_app/core/exceptions/api_exceptions.dart';

import '../../../domain/services/auth_service.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthService authService;
  LoginBloc(this.authService) : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  Future<void> _onLoginSubmitted(LoginSubmitted e, Emitter<LoginState> emit) async {
    emit(LoginLoading());
    try {
      await authService.login(e.email, e.password);
      emit(LoginSuccess());
    } on ApiException catch (err) {
      emit(LoginFailure(err.message));
    } catch (err) {
      emit(LoginFailure('Login failed'));
    }
  }
}


