import '../../data/response/family_top_wallets_response.dart';
import '../entities/family_top_wallets_model.dart';

extension FamilyTopWalletsTranslator on FamilyTopWalletsResponse {
  FamilyTopWalletsModel toFamilyTopWalletsModel() {
    return FamilyTopWalletsModel(
      total: total,
      count: count,
      userId: userId,
      username: username,
      email: email,
    );
  }
}
