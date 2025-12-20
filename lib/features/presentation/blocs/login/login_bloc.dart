import 'package:finance_management_app/core/di/injector.dart';
import 'package:finance_management_app/core/network/api_result.dart';
import 'package:finance_management_app/features/app/presentation/bloc/app_cubit.dart';
import 'package:finance_management_app/features/presentation/blocs/login/login_event.dart';
import 'package:finance_management_app/features/presentation/blocs/login/login_state.dart';
import 'package:finance_management_app/features/presentation/blocs/user/user_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/repository/auth_repository.dart';

@injectable
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository authRepository;
  LoginBloc(this.authRepository) : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LoginWithGoogleSubmitted>(_onLoginWithGoogleSubmitted);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());

    final loginResult = await authRepository.login(
      email: event.email,
      password: event.password,
    );

    if (loginResult.isFailure) {
      emit(LoginFailure(loginResult.error));
      return;
    }

    final profileResult = await authRepository.getMyProfile();

    if (profileResult.isFailure) {
      emit(LoginFailure(profileResult.error));
      return;
    }

    // Load user vào UserBloc
    if (profileResult.isSuccess) {
      getIt<UserBloc>().add(UpdateUser(profileResult.data));
    }

    getIt<AppCubit>().onLoggedIn();
    emit(LoginSuccess());
  }

  Future<void> _onLoginWithGoogleSubmitted(
    LoginWithGoogleSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginWithGoogleLoading());

    final result = await authRepository.loginWithGoogle();

    if (result.isFailure) {
      emit(LoginWithGoogleFailure(result.error));
      return;
    }

    final profileResult = await authRepository.getMyProfile();

    if (profileResult.isFailure) {
      emit(LoginWithGoogleFailure(profileResult.error));
      return;
    }

    // Load user vào UserBloc
    if (profileResult.isSuccess) {
      getIt<UserBloc>().add(UpdateUser(profileResult.data));
    }

    getIt<AppCubit>().onLoggedIn();
    emit(LoginWithGoogleSuccess());
  }
}
