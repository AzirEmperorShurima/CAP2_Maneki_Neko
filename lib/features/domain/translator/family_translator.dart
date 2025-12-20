import '../../data/response/family_response.dart';
import '../entities/family_model.dart';

extension FamilyTranslator on FamilyResponse {
  FamilyModel toFamilyModel() {
    return FamilyModel(
      id: id,
      name: name,
      inviteCode: inviteCode,
      isActive: isActive,
      adminId: adminId,
      sharedResources: sharedResources?.toFamilySharedResources(),
      sharingSettings: sharingSettings?.toFamilySharingSettings(),
      admin: admin,
      members: members,
      pendingInvites: pendingInvites,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension FamilySharedResourcesTranslator on FamilySharedResourcesResponse {
  FamilySharedResources toFamilySharedResources() {
    return FamilySharedResources(
      budgets: budgets,
      wallets: wallets,
      goals: goals,
    );
  }
}

extension FamilySharingSettingsTranslator on FamilySharingSettingsResponse {
  FamilySharingSettings toFamilySharingSettings() {
    return FamilySharingSettings(
      transactionVisibility: transactionVisibility,
      walletVisibility: walletVisibility,
      goalVisibility: goalVisibility,
    );
  }
}
