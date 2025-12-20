import 'package:json_annotation/json_annotation.dart';

part 'wallet_summary_response.g.dart';

@JsonSerializable()
class WalletSummaryResponse {
  final String? id;
  final String? name;
  final String? type;
  final String? icon;
  @JsonKey(name: 'currentBalance')
  final num? currentBalance;

  WalletSummaryResponse({
    this.id,
    this.name,
    this.type,
    this.icon,
    this.currentBalance,
  });

  factory WalletSummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$WalletSummaryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WalletSummaryResponseToJson(this);
}
