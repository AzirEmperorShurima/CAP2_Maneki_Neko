import 'package:json_annotation/json_annotation.dart';

part 'user_response.g.dart';

@JsonSerializable()
class UserResponse {
  final String? id;

  final String? email;

  final String username;

  final String? avatar;

  // final String? family;

  final bool? isFamilyAdmin;

  UserResponse({
    required this.id,
    required this.email,
    required this.username,
    this.avatar,
    // this.family,
    this.isFamilyAdmin,
  });
  factory UserResponse.fromJson(Map<String, dynamic> json) =>
      _$UserResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UserResponseToJson(this);
}
