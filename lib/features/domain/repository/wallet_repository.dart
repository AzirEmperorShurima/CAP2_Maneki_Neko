import 'package:finance_management_app/core/network/api_result.dart';
import 'package:finance_management_app/features/domain/entities/wallet_model.dart';

import '../../data/requests/wallet_request.dart';
import '../../data/requests/wallet_transfer_request.dart';

abstract class WalletRepository {
  Future<ApiResult<List<WalletModel>?>> getWallets();

  Future<ApiResult<WalletModel?>> createWallet(WalletRequest? request);

  Future<ApiResult<WalletModel?>> updateWallet(String id, WalletRequest? request);

  Future<ApiResult<void>> deleteWallet(String id);

  Future<ApiResult<void>> transferWallet(WalletTransferRequest? request);
}
