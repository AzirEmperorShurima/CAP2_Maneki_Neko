import 'package:json_annotation/json_annotation.dart';

import 'category_model.dart';
import 'user_model.dart';
import 'wallet_model.dart';

part 'transaction_model.g.dart';

@JsonSerializable()
class TransactionModel {
  final String? id;

  final num? amount;

  final String? type;

  final DateTime? date;

  final String? description;

  final bool? isShared;

  final String? expenseFor;

  final bool? isOwner;

  final UserModel? owner;

  final CategoryModel? category;

  final WalletModel? wallet;

  TransactionModel({
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

  factory TransactionModel.fromJson(Map<String, dynamic> json) => _$TransactionModelFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);
}