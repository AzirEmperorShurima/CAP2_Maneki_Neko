import 'package:finance_management_app/features/data/response/family_invite_response.dart';

import '../entities/family_invite_model.dart';

extension FamilyInviteTranslator on FamilyInviteResponse {
  FamilyInviteModel toFamilyInviteModel() {
    return FamilyInviteModel(
      webJoinLink: webJoinLink,
      deepLink: deepLink,
      userExists: userExists,
    );
  }
}
