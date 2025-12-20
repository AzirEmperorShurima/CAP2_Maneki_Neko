import 'package:finance_management_app/features/data/response/auth_response.dart';

import '../entities/auth_model.dart';

extension AuthTranslator on AuthResponse {
  AuthModel toAuthModel() {
    return AuthModel(
      accessToken: accessToken,
      userId: userId,
    );
  }
}
