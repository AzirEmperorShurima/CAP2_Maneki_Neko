import 'package:json_annotation/json_annotation.dart';

part 'wallet_summary_model.g.dart';

/// Model tóm tắt thông tin ví (dùng cho wallet analysis)
/// Tái sử dụng một phần từ WalletModel nhưng chỉ lấy các field cần thiết
@JsonSerializable()
class WalletSummaryModel {
  final String? id;
  final String? name;
  final String? type;
  final String? icon;
  @JsonKey(name: 'currentBalance')
  final num? balance;

  WalletSummaryModel({
    this.id,
    this.name,
    this.type,
    this.icon,
    this.balance,
  });

  factory WalletSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$WalletSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$WalletSummaryModelToJson(this);
}

