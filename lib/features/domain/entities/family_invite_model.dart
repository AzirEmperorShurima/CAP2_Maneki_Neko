import 'package:json_annotation/json_annotation.dart';

part 'family_invite_model.g.dart';

@JsonSerializable()
class FamilyInviteModel {
  final String webJoinLink;
  final String deepLink;
  final bool userExists;

  FamilyInviteModel({
    required this.webJoinLink,
    required this.deepLink,
    required this.userExists,
  });

  factory FamilyInviteModel.fromJson(Map<String, dynamic> json) =>
      _$FamilyInviteModelFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyInviteModelToJson(this);
}
