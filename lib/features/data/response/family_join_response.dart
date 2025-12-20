import 'package:json_annotation/json_annotation.dart';

part 'family_join_response.g.dart';

@JsonSerializable()
class FamilyJoinResponse {
  final String id;
  final String name;
  
  @JsonKey(name: 'admin_id')
  final String adminId;
  
  final List<String> members;

  FamilyJoinResponse({
    required this.id,
    required this.name,
    required this.adminId,
    required this.members,
  });

  factory FamilyJoinResponse.fromJson(Map<String, dynamic> json) =>
      _$FamilyJoinResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyJoinResponseToJson(this);
}
