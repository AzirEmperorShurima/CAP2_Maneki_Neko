import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String? id;

  final String? email;

  final String? username;

  final String? avatar;

  final String? family;

  final bool? isFamilyAdmin;

  const UserModel({
    this.id,
    this.email,
    this.username,
    this.avatar,
    this.family,
    this.isFamilyAdmin,
  });
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
