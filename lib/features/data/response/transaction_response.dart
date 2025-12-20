import 'package:json_annotation/json_annotation.dart';

import 'category_response.dart';
import 'user_response.dart';
import 'wallet_response.dart';

part 'transaction_response.g.dart';

@JsonSerializable()
class TransactionResponse {
  final String? id;

  final num? amount;

  final String? type;

  final DateTime? date;

  final String? description;

  final bool? isShared;

  @JsonKey(name: 'expense_for')
  final String? expenseFor;

  final bool? isOwner;

  final UserResponse? owner;

  final CategoryResponse? category;

  final WalletResponse? wallet;

  TransactionResponse({
    this.id,
    this.amount,
    this.type,
    this.date,
    this.description,
    this.isShared,
    this.expenseFor,
    this.isOwner,
    this.owner,
    this.category,
    this.wallet,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) => _$TransactionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionResponseToJson(this);
}