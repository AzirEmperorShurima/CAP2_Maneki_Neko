import '../../data/response/wallet_response.dart';
import '../entities/wallet_model.dart';

extension WalletTranslator on WalletResponse {
  WalletModel toWalletModel() {
    return WalletModel(
      id: id,
      name: name,
      type: type,
      scope: scope,
      balance: balance,
      isActive: isActive,
      isShared: isShared,
      isDefault: isDefault,
      isSystemWallet: isSystemWallet,
      canDelete: canDelete,
      description: description,
      icon: icon,
      createdAt: createdAt,
      updatedAt: updatedAt,
      userId: userId,
    );
  }
}
