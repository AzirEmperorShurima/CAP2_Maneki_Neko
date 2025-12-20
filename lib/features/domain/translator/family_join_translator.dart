import 'package:finance_management_app/features/data/response/family_join_response.dart';

import '../entities/family_join_model.dart';

extension FamilyJoinTranslator on FamilyJoinResponse {
  FamilyJoinModel toFamilyJoinModel() {
    return FamilyJoinModel(
      id: id,
      name: name,
      adminId: adminId,
      members: members,
    );
  }
}
