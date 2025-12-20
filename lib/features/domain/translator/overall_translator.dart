import 'package:finance_management_app/features/domain/translator/amount_translator.dart';
import 'package:finance_management_app/features/domain/translator/period_translator.dart';

import '../../data/response/overall_response.dart';
import '../entities/overall_model.dart';

extension OverallTranslator on OverallResponse {
  OverallModel toOverallModel() => OverallModel(
    income: income?.toAmountModel(),
    expense: expense?.toAmountModel(),
    netBalance: netBalance,
    totalWalletBalance: totalWalletBalance,
    walletsCount: walletsCount,
    period: period?.toPeriodModel(),
  );
}