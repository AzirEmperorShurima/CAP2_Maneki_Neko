import 'package:finance_management_app/features/data/response/amount_response.dart';
import 'package:finance_management_app/features/domain/entities/amount_model.dart';

extension AmountTranslator on AmountResponse {
  AmountModel toAmountModel() => AmountModel(
        total: total,
        count: count,
      );
}
