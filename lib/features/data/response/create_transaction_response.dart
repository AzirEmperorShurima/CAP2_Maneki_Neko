import 'package:json_annotation/json_annotation.dart';

import 'budget_warning_response.dart';
import 'transaction_response.dart';

part 'create_transaction_response.g.dart';

@JsonSerializable()
class CreateTransactionResponse {
  final TransactionResponse? transaction;
  
  @JsonKey(name: 'budgetWarnings')
  final BudgetWarningResponse? budgetWarnings;

  CreateTransactionResponse({
    this.transaction,
    this.budgetWarnings,
  });

  factory CreateTransactionResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateTransactionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreateTransactionResponseToJson(this);
}
