import 'package:json_annotation/json_annotation.dart';

part 'family_top_wallets_response.g.dart';

@JsonSerializable()
class FamilyTopWalletsResponse {
  final double? total;
  final int? count;
  @JsonKey(name: 'userId')
  final String? userId;
  final String? username;
  final String? email;

  FamilyTopWalletsResponse({
    this.total,
    this.count,
    this.userId,
    this.username,
    this.email,
  });

  factory FamilyTopWalletsResponse.fromJson(Map<String, dynamic> json) =>
      _$FamilyTopWalletsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyTopWalletsResponseToJson(this);
}
