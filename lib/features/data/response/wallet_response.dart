import 'package:json_annotation/json_annotation.dart';

part 'wallet_response.g.dart';

@JsonSerializable()
class WalletResponse {
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

  WalletResponse({
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

  factory WalletResponse.fromJson(Map<String, dynamic> json) => _$WalletResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WalletResponseToJson(this);
}