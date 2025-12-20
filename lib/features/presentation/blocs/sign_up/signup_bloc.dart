import 'package:finance_management_app/core/network/api_result.dart';
import 'package:finance_management_app/features/presentation/blocs/sign_up/signup_event.dart';
import 'package:finance_management_app/features/presentation/blocs/sign_up/signup_state.dart';
import 'package:finance_management_app/features/presentation/blocs/user/user_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/di/injector.dart';
import '../../../app/presentation/bloc/app_cubit.dart';
import '../../../domain/repository/auth_repository.dart';

@injectable
class SignupBloc extends Bloc<SignupEvent, SignupState> {
  final AuthRepository authRepository;
  SignupBloc(this.authRepository) : super(SignupInitial()) {
    on<SignupSubmitted>(_onSignupSubmitted);
  }

  Future<void> _onSignupSubmitted(
    SignupSubmitted event,
    Emitter<SignupState> emit,
  ) async {
    emit(SignupLoading());

    final result = await authRepository.register(
      email: event.email,
      password: event.password,
    );

    if(result.isFailure) {
      emit(SignupFailure(result.error));
      return;
    }

    final profileResult = await authRepository.getMyProfile();

    if(profileResult.isFailure) {
      emit(SignupFailure(profileResult.error));
      return;
    }

    // Load user vào UserBloc
    if (profileResult.isSuccess) {
      getIt<UserBloc>().add(UpdateUser(profileResult.data));
    }

    getIt<AppCubit>().onLoggedIn();
    emit(SignupSuccess());
  }
}
