import 'package:finance_management_app/core/common/enums/auth_status.dart';
import 'package:finance_management_app/core/infrastructure/secure_storage_service.dart';
import 'package:finance_management_app/utils/utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'app_cubit.freezed.dart';
part 'app_state.dart';

@LazySingleton()
class AppCubit extends Cubit<AppState> {
  final SecureStorageService _storageService;
  
  AppCubit(this._storageService) : super(const AppState());

  /// Kiểm tra user đã đăng nhập chưa
  bool get isLoggedIn {
    // Có thể check token hoặc user data
    // Tạm thời dùng Utils, sau có thể dùng SecureStorageService
    return false; // Sẽ được implement sau
  }

  /// Xử lý logic khi mở app
  Future<void> openApp() async {
    // Delay để hiển thị splash screen
    await Future.delayed(const Duration(milliseconds: 2000));
    
    final token = await _storageService.readAccessToken();
    final isLoggedIn = await Utils.getIsLoggedIn();
    
    if (token != null && token.isNotEmpty && isLoggedIn) {
      emit(state.copyWith(authStatus: AuthStatus.authenticated));
      // Load user data khi app khởi động nếu đã đăng nhập
      // LoadUser sẽ được dispatch trong App listener khi authStatus thay đổi
    } else {
      emit(state.copyWith(authStatus: AuthStatus.unauthenticated));
    }
  }

  /// Khi user đăng nhập thành công
  void onLoggedIn() {
    emit(state.copyWith(authStatus: AuthStatus.authenticated));
  }

  /// Logout user
  Future<void> logout({String? errorMessage}) async {
    emit(state.copyWith(authStatus: AuthStatus.unknown));
    await _storageService.clear();
    await Utils.setIsLoggedIn(false);
    // Reset flag để user mới đăng nhập có thể thấy dialog hướng dẫn tạo ví
    await Utils.setHasShownWalletDialog(false);
    emit(state.copyWith(authStatus: AuthStatus.unauthenticated));
  }

  /// Reset về màn hình đăng nhập
  void navigateResetToSignIn() {
    emit(state.copyWith(authStatus: AuthStatus.unauthenticated));
  }
}

