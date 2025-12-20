import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user_model.dart';

part 'family_response.g.dart';

@JsonSerializable()
class FamilyResponse {
  final String? id;
  final String? name;
  final String? inviteCode;
  final bool? isActive;
  
  @JsonKey(name: 'admin_id')
  final String? adminId;
  
  final FamilySharedResourcesResponse? sharedResources;
  final FamilySharingSettingsResponse? sharingSettings;
  final UserModel? admin;
  final List<UserModel>? members;
  final List<UserModel>? pendingInvites;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FamilyResponse({
    this.id,
    this.name,
    this.inviteCode,
    this.isActive,
    this.adminId,
    this.sharedResources,
    this.sharingSettings,
    this.admin,
    this.members,
    this.pendingInvites,
    this.createdAt,
    this.updatedAt,
  });

  factory FamilyResponse.fromJson(Map<String, dynamic> json) =>
      _$FamilyResponseFromJson(json);
  Map<String, dynamic> toJson() => _$FamilyResponseToJson(this);
}

@JsonSerializable()
class FamilySharedResourcesResponse {
  final List<dynamic>? budgets;
  final List<dynamic>? wallets;
  final List<dynamic>? goals;

  const FamilySharedResourcesResponse({
    this.budgets,
    this.wallets,
    this.goals,
  });

  factory FamilySharedResourcesResponse.fromJson(Map<String, dynamic> json) =>
      _$FamilySharedResourcesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$FamilySharedResourcesResponseToJson(this);
}

@JsonSerializable()
class FamilySharingSettingsResponse {
  final String? transactionVisibility;
  final String? walletVisibility;
  final String? goalVisibility;

  const FamilySharingSettingsResponse({
    this.transactionVisibility,
    this.walletVisibility,
    this.goalVisibility,
  });

  factory FamilySharingSettingsResponse.fromJson(Map<String, dynamic> json) =>
      _$FamilySharingSettingsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$FamilySharingSettingsResponseToJson(this);
}
