import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finance_management_app/features/presentation/blocs/sign_up/signup_event.dart';
import 'package:finance_management_app/features/presentation/blocs/sign_up/signup_state.dart';
import 'package:finance_management_app/core/exceptions/api_exceptions.dart';

import '../../../domain/services/auth_service.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  final AuthService authService;
  SignupBloc(this.authService) : super(SignupInitial()) {
    on<SignupSubmitted>(_onSignupSubmitted);
  }

  Future<void> _onSignupSubmitted(SignupSubmitted e, Emitter<SignupState> emit) async {
    emit(SignupLoading());
    try {
      await authService.register(e.name, e.email, e.password);
      emit(SignupSuccess());
    } on ApiException catch (err) {
      emit(SignupFailure(err.message));
    } catch (_) {
      emit(SignupFailure('Signup failed'));
    }
  }
}


