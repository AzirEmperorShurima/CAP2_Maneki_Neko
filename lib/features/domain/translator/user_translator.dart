import '../../data/response/user_response.dart';
import '../entities/user_model.dart';

extension UserTranslator on UserResponse {
  UserModel toUserModel() {
    return UserModel(
      id: id,
      email: email,
      username: username,
      avatar: avatar,
      // family: family,
      isFamilyAdmin: isFamilyAdmin,
    );
  }
}
