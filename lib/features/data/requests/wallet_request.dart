import 'package:json_annotation/json_annotation.dart';

part 'wallet_request.g.dart';

@JsonSerializable()
class WalletRequest {
  final String? name;

  final String? type;

  final num? balance;

  final String? description;

  final bool? isDefault;

  WalletRequest({
    this.name,
    this.type,
    this.balance,
    this.description,
    this.isDefault,
  });

  factory WalletRequest.fromJson(Map<String, dynamic> json) => _$WalletRequestFromJson(json);

  Map<String, dynamic> toJson() => _$WalletRequestToJson(this);
}