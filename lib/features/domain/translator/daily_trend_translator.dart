import '../../data/response/daily_trend_response.dart';
import '../entities/daily_trend_model.dart';

extension DailyTrendTranslator on DailyTrendResponse {
  DailyTrendModel toDailyTrendModel() {
    return DailyTrendModel(
      date: date,
      income: income,
      expense: expense,
    );
  }
}
