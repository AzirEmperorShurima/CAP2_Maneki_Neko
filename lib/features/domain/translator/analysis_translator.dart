import 'package:finance_management_app/features/data/response/analysis_response.dart';
import 'package:finance_management_app/features/domain/entities/analysis_model.dart';
import 'package:finance_management_app/features/domain/translator/overall_translator.dart';

extension AnalysisTranslator on AnalysisResponse {
  AnalysisModel toAnalysisModel() => AnalysisModel(
    overall: overall?.toOverallModel(),
  );
}