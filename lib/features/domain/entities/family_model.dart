import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'family_model.g.dart';

@JsonSerializable()
class FamilyModel {
  final String? id;
  final String? name;
  final String? inviteCode;
  final bool? isActive;
  
  @JsonKey(name: 'admin_id')
  final String? adminId;
  final FamilySharedResources? sharedResources;
  final FamilySharingSettings? sharingSettings;
  final UserModel? admin;
  final List<UserModel>? members;
  final List<UserModel>? pendingInvites;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FamilyModel({
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

  factory FamilyModel.fromJson(Map<String, dynamic> json) =>
      _$FamilyModelFromJson(json);
  Map<String, dynamic> toJson() => _$FamilyModelToJson(this);
}

@JsonSerializable()
class FamilySharedResources {
  final List<dynamic>? budgets;
  final List<dynamic>? wallets;
  final List<dynamic>? goals;

  const FamilySharedResources({
    this.budgets,
    this.wallets,
    this.goals,
  });

  factory FamilySharedResources.fromJson(Map<String, dynamic> json) =>
      _$FamilySharedResourcesFromJson(json);
  Map<String, dynamic> toJson() => _$FamilySharedResourcesToJson(this);
}

@JsonSerializable()
class FamilySharingSettings {
  final String? transactionVisibility;
  final String? walletVisibility;
  final String? goalVisibility;

  const FamilySharingSettings({
    this.transactionVisibility,
    this.walletVisibility,
    this.goalVisibility,
  });

  factory FamilySharingSettings.fromJson(Map<String, dynamic> json) =>
      _$FamilySharingSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$FamilySharingSettingsToJson(this);
}
