import 'package:json_annotation/json_annotation.dart';

part 'family_join_model.g.dart';

@JsonSerializable()
class FamilyJoinModel {
  final String id;
  final String name;
  
  @JsonKey(name: 'admin_id')
  final String adminId;
  
  final List<String> members;

  FamilyJoinModel({
    required this.id,
    required this.name,
    required this.adminId,
    required this.members,
  });

  factory FamilyJoinModel.fromJson(Map<String, dynamic> json) =>
      _$FamilyJoinModelFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyJoinModelToJson(this);
}
