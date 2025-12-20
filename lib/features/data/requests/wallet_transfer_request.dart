import 'package:json_annotation/json_annotation.dart';

part 'wallet_transfer_request.g.dart';

@JsonSerializable()
class WalletTransferRequest {
  final String? fromWalletId;

  final String? toWalletId;

  final num? amount;

  final String? note;

  WalletTransferRequest({
    this.fromWalletId,
    this.toWalletId,
    this.amount,
    this.note,
  });

  factory WalletTransferRequest.fromJson(Map<String, dynamic> json) => _$WalletTransferRequestFromJson(json);

  Map<String, dynamic> toJson() => _$WalletTransferRequestToJson(this);
}
