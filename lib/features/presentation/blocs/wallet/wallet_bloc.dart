import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:finance_management_app/features/domain/entities/wallet_model.dart';
import 'package:finance_management_app/features/domain/repository/wallet_repository.dart';
import 'package:injectable/injectable.dart';

import '../../../data/requests/wallet_request.dart';
import '../../../data/requests/wallet_transfer_request.dart';

part 'wallet_event.dart';
part 'wallet_state.dart';

@injectable
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletRepository walletRepository;

  WalletBloc(this.walletRepository) : super(WalletInitial()) {
    on<LoadWalletsSubmitted>(_onLoadWalletsSubmitted);
    on<RefreshWallets>(_onRefreshWallets);
    on<CreateWalletSubmitted>(_onCreateWalletSubmitted);
    on<UpdateWalletSubmitted>(_onUpdateWalletSubmitted);
    on<DeleteWalletSubmitted>(_onDeleteWalletSubmitted);
    on<TransferWalletSubmitted>(_onTransferWalletSubmitted);
    on<ResetWallets>(_onResetWallets);
  }

  Future<void> _onLoadWalletsSubmitted(
    LoadWalletsSubmitted event,
    Emitter<WalletState> emit,
  ) async {
    // Kiểm tra xem đã có data chưa (chỉ skip nếu đã có data)
    // Sau khi reset về WalletInitial, sẽ gọi API lại
    final currentState = state;
    if (currentState is WalletLoaded && currentState.wallets.isNotEmpty) {
      // Đã có data hợp lệ, không cần gọi API lại
      return;
    }

    emit(WalletLoading());

    final result = await walletRepository.getWallets();

    result.when(
      success: (data) {
        emit(WalletLoaded(data ?? []));
      },
      failure: (error) {
        emit(WalletFailure(error));
      },
    );
  }

  void _onResetWallets(
    ResetWallets event,
    Emitter<WalletState> emit,
  ) {
    emit(WalletInitial());
  }

  Future<void> _onRefreshWallets(
    RefreshWallets event,
    Emitter<WalletState> emit,
  ) async {
    final currentState = state;
    if (currentState is WalletLoaded) {
      emit(WalletRefreshing(currentState.wallets));
    } else {
      emit(WalletLoading());
    }

    final result = await walletRepository.getWallets();

    result.when(
      success: (data) {
        emit(WalletLoaded(data ?? []));
      },
      failure: (error) {
        emit(WalletFailure(error));
      },
    );
  }

  Future<void> _onCreateWalletSubmitted(
    CreateWalletSubmitted event,
    Emitter<WalletState> emit,
  ) async {
    emit(WalletCreating());

    final request = WalletRequest(
      name: event.name,
      type: event.type,
      balance: event.balance,
      description: event.description,
      isDefault: event.isDefault,
    );

    final result = await walletRepository.createWallet(request);

    result.when(
      success: (data) {
        if (data != null) {
          emit(WalletCreated(data));
        } else {
          emit(WalletCreateFailure('Không thể tạo ví'));
        }
      },
      failure: (error) {
        emit(WalletCreateFailure(error));
      },
    );
  }

  Future<void> _onUpdateWalletSubmitted(
    UpdateWalletSubmitted event,
    Emitter<WalletState> emit,
  ) async {
    emit(WalletUpdating(event.walletId));

    final request = WalletRequest(
      name: event.name,
      type: event.type,
      balance: event.balance,
      description: event.description,
      isDefault: event.isDefault,
    );

    final result = await walletRepository.updateWallet(event.walletId, request);

    result.when(
      success: (data) {
        if (data != null) {
          emit(WalletUpdated(data));
        } else {
          emit(WalletUpdateFailure('Không thể cập nhật ví'));
        }
      },
      failure: (error) {
        emit(WalletUpdateFailure(error));
      },
    );
  }

  Future<void> _onDeleteWalletSubmitted(
    DeleteWalletSubmitted event,
    Emitter<WalletState> emit,
  ) async {
    emit(WalletDeleting(event.walletId));

    final result = await walletRepository.deleteWallet(event.walletId);

    result.when(
      success: (_) {
        emit(WalletDeleted(event.walletId));
      },
      failure: (error) {
        emit(WalletDeleteFailure(error));
      },
    );
  }

  Future<void> _onTransferWalletSubmitted(
    TransferWalletSubmitted event,
    Emitter<WalletState> emit,
  ) async {
    emit(WalletTransferring());

    final request = WalletTransferRequest(
      fromWalletId: event.fromWalletId,
      toWalletId: event.toWalletId,
      amount: event.amount,
      note: event.note,
    );

    final result = await walletRepository.transferWallet(request);

    result.when(
      success: (_) {
        emit(WalletTransferred());
      },
      failure: (error) {
        emit(WalletTransferFailure(error));
      },
    );
  }
}

