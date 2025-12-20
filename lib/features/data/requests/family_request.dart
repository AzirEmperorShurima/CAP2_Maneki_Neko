import 'package:json_annotation/json_annotation.dart';

part 'family_request.g.dart';

@JsonSerializable()
class FamilyInviteRequest {
  final String email;

  FamilyInviteRequest({
    required this.email,
  });

  factory FamilyInviteRequest.fromJson(Map<String, dynamic> json) =>
      _$FamilyInviteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyInviteRequestToJson(this);
}

@JsonSerializable()
class FamilyJoinRequest {
  final String familyCode;

  FamilyJoinRequest({
    required this.familyCode,
  });

  factory FamilyJoinRequest.fromJson(Map<String, dynamic> json) =>
      _$FamilyJoinRequestFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyJoinRequestToJson(this);
}

@JsonSerializable()
class FamilyCreateRequest {
  final String name;

  FamilyCreateRequest({
    required this.name,
  });

  factory FamilyCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$FamilyCreateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyCreateRequestToJson(this);
}
