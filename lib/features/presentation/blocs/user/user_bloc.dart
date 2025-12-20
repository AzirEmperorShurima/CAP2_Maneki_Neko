import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:finance_management_app/core/infrastructure/secure_storage_service.dart';
import 'package:finance_management_app/features/domain/entities/user_model.dart';
import 'package:injectable/injectable.dart';

part 'user_event.dart';
part 'user_state.dart';

@lazySingleton
class UserBloc extends Bloc<UserEvent, UserState> {
  final SecureStorageService storage;

  UserBloc(this.storage) : super(UserInitial()) {
    on<LoadUser>(_onLoadUser);
    on<UpdateUser>(_onUpdateUser);
  }

  Future<void> _onLoadUser(
    LoadUser event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    
    final user = await storage.getUserData();
    
    if (user != null) {
      emit(UserLoaded(user));
    } else {
      emit(UserFailure('Không tìm thấy thông tin người dùng'));
    }
  }

  Future<void> _onUpdateUser(
    UpdateUser event,
    Emitter<UserState> emit,
  ) async {
      // Lưu user mới vào storage
      await storage.saveUserData(event.user);
    // Luôn emit UserLoaded bất kể state hiện tại
      emit(UserLoaded(event.user));
  }
}
