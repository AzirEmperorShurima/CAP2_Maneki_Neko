import 'package:json_annotation/json_annotation.dart';

import 'budget_warning_model.dart';
import 'transaction_model.dart';

part 'create_transaction_model.g.dart';

@JsonSerializable()
class CreateTransactionModel {
  final TransactionModel? transaction;
  final BudgetWarningModel? budgetWarnings;

  CreateTransactionModel({
    this.transaction,
    this.budgetWarnings,
  });

  factory CreateTransactionModel.fromJson(Map<String, dynamic> json) =>
      _$CreateTransactionModelFromJson(json);
  Map<String, dynamic> toJson() => _$CreateTransactionModelToJson(this);
}
