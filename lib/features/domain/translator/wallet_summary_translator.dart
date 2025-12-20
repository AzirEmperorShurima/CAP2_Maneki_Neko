import '../../data/response/wallet_summary_response.dart';
import '../entities/wallet_summary_model.dart';

extension WalletSummaryTranslator on WalletSummaryResponse {
  WalletSummaryModel toWalletSummaryModel() {
    return WalletSummaryModel(
      id: id,
      name: name,
      type: type,
      icon: icon,
      balance: currentBalance,
    );
  }
}
