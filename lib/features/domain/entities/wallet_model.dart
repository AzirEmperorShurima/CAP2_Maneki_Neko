import 'package:json_annotation/json_annotation.dart';

part 'wallet_model.g.dart';

@JsonSerializable()
class WalletModel {
  final String? id;

  final String? name;

  final String? type;

  final String? scope;

  final num? balance;

  final bool? isActive;

  final bool? isShared;

  final bool? isDefault;

  final bool? isSystemWallet;

  final bool? canDelete;

  final String? description;

  final String? icon;

  final DateTime? createdAt;

  final DateTime? updatedAt;

  final String? userId;

  WalletModel({
    this.id,
    this.name,
    this.type,
    this.scope,
    this.balance,
    this.isActive,
    this.isShared,
    this.isDefault,
    this.isSystemWallet,
    this.canDelete,
    this.description,
    this.icon,
    this.createdAt,
    this.updatedAt,
    this.userId,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) => _$WalletModelFromJson(json);

  Map<String, dynamic> toJson() => _$WalletModelToJson(this);
}