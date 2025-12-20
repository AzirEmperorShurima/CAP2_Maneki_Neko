import 'package:finance_management_app/features/data/response/category_response.dart';
import '../entities/category_model.dart';

extension CategoryTranslator on CategoryResponse {
  CategoryModel toCategoryModel() {
    return CategoryModel(
      id: id,
      name: name,
      type: type,
      image: image,
    );
  }
}