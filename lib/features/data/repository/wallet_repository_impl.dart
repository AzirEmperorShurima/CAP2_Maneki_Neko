import 'package:finance_management_app/features/domain/translator/wallet_translator.dart';
import 'package:injectable/injectable.dart';

import '../../../core/common/bases/base_repository.dart';
import '../../../core/network/api_result.dart';
import '../../domain/entities/wallet_model.dart';
import '../../domain/repository/wallet_repository.dart';
import '../remote/api_client.dart';
import '../requests/wallet_request.dart';
import '../requests/wallet_transfer_request.dart';
import '../response/wallet_response.dart';

@LazySingleton(as: WalletRepository)
class WalletRepositoryImpl extends BaseRepository implements WalletRepository {
  final ApiClient apiClient;

  WalletRepositoryImpl(this.apiClient);

  @override
  Future<ApiResult<List<WalletModel>?>> getWallets() {
    return handleApiResponse<List<WalletModel>?>(
      () async {
        final response = await apiClient.getWallets();

        final walletResponses = response.getItems(
          WalletResponse.fromJson,
          fromKey: 'wallets',
        );

        return walletResponses
            ?.map((response) => response.toWalletModel())
            .toList();
      },
    );
  }

  @override
  Future<ApiResult<WalletModel?>> createWallet(WalletRequest? request) {
    return handleApiResponse<WalletModel?>(
      () async {
        final response = await apiClient.createWallet(request);

        final walletResponse = response
            .getBody(WalletResponse.fromJson, fromKey: 'wallet')
            ?.toWalletModel();

        return walletResponse;
      },
    );
  }

  @override
  Future<ApiResult<WalletModel?>> updateWallet(String id, WalletRequest? request) {
    return handleApiResponse<WalletModel?>(
      () async {
        final response = await apiClient.updateWallet(id, request);

        final walletResponse = response
            .getBody(WalletResponse.fromJson, fromKey: 'wallet')
            ?.toWalletModel();

        return walletResponse;
      },
    );
  }

  @override
  Future<ApiResult<void>> deleteWallet(String id) {
    return handleApiResponse<void>(
      () async {
        final response = await apiClient.deleteWallet(id);
        
        return response;
      },
    );
  }

  @override
  Future<ApiResult<void>> transferWallet(WalletTransferRequest? request) {
    return handleApiResponse<void>(
      () async {
        final response = await apiClient.walletTransfer(request);
        return response;
      },
    );
  }
}
