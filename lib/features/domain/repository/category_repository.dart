import 'package:finance_management_app/core/network/api_result.dart';
import 'package:finance_management_app/features/domain/entities/category_image_model.dart';
import 'package:finance_management_app/features/domain/entities/category_model.dart';

abstract class CategoryRepository {
  Future<ApiResult<List<CategoryModel>?>> getCategories(String? type);
  
  Future<ApiResult<List<CategoryImageModel>?>> getCategoryImages({
    String? folder,
    int? limit,
    String? cursor,
  });

  Future<ApiResult<CategoryModel?>> createCategory({
    String? name,
    String? type,
    String? image,
  });
}