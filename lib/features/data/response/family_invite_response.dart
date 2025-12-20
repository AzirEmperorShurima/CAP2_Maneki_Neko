import 'package:json_annotation/json_annotation.dart';

part 'family_invite_response.g.dart';

@JsonSerializable()
class FamilyInviteResponse {
  final String webJoinLink;
  final String deepLink;
  final bool userExists;

  FamilyInviteResponse({
    required this.webJoinLink,
    required this.deepLink,
    required this.userExists,
  });

  factory FamilyInviteResponse.fromJson(Map<String, dynamic> json) =>
      _$FamilyInviteResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyInviteResponseToJson(this);
}
