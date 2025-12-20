import 'package:finance_management_app/features/data/response/period_response.dart';
import 'package:finance_management_app/features/domain/entities/period_model.dart';

extension PeriodTranslator on PeriodResponse {
  PeriodModel toPeriodModel() => PeriodModel(
        startDate: startDate,
        endDate: endDate,
      );
}
