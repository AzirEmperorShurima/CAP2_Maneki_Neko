import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:finance_management_app/core/di/injector.dart';
import 'package:finance_management_app/features/app/presentation/bloc/app_cubit.dart';
import 'package:finance_management_app/features/domain/repository/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

part 'settings_event.dart';
part 'settings_state.dart';

@injectable
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final AuthRepository authRepository;
  SettingsBloc(this.authRepository) : super(SettingsInitial()) {
    on<SettingsLogout>(_onLogout);
  }

  Future<void> _onLogout(
    SettingsLogout event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLogoutLoading());
    
    final result = await authRepository.logout();

    result.when(
      success: (data) {
        getIt<AppCubit>().logout();
        emit(SettingsLogoutSuccess());
      },
      failure: (error) {
        getIt<AppCubit>().logout();
        emit(SettingsLogoutSuccess());
      },
    );
  }
}
