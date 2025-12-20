import 'package:finance_management_app/features/domain/repository/category_repository.dart';
import 'package:finance_management_app/features/domain/translator/category_image_translator.dart';
import 'package:finance_management_app/features/domain/translator/category_translator.dart';
import 'package:injectable/injectable.dart';

import '../../../core/common/bases/base_repository.dart';
import '../../../core/network/api_result.dart';
import '../../domain/entities/category_image_model.dart';
import '../../domain/entities/category_model.dart';
import '../remote/api_client.dart';
import '../requests/category_request.dart';
import '../response/category_image_response.dart';
import '../response/category_response.dart';

@LazySingleton(as: CategoryRepository)
class CategoryRepositoryImpl extends BaseRepository
    implements CategoryRepository {
  final ApiClient apiClient;

  CategoryRepositoryImpl(this.apiClient);

  @override
  Future<ApiResult<List<CategoryModel>>> getCategories(String? type) {
    return handleApiResponse<List<CategoryModel>>(
      () async {
        final response = await apiClient.getCategories(type);

        final categoryResponses = response.getItems(
          CategoryResponse.fromJson,
          fromKey: 'data',
        );

        return categoryResponses
            ?.map((response) => response.toCategoryModel())
            .toList() ?? [];
      },
    );
  }

  @override
  Future<ApiResult<List<CategoryImageModel>?>> getCategoryImages({
    String? folder,
    int? limit,
    String? cursor,
  }) {
    return handleApiResponse<List<CategoryImageModel>?>(
      () async {
        final response = await apiClient.getCategoryImages(
          folder,
          limit,
          cursor,
        );

        final imageResponses = response.getItems(
          CategoryImageResponse.fromJson,
          fromKey: 'images',
        );

        return imageResponses
            ?.map((response) => response.toCategoryImageModel())
            .toList();
      },
    );
  }

  @override
  Future<ApiResult<CategoryModel?>> createCategory({
    String? name,
    String? type,
    String? image,
  }) {
    return handleApiResponse<CategoryModel?>(
      () async {
        final request = CategoryRequest(
          name: name,
          type: type,
          image: image,
        );
        final response = await apiClient.createCategory(request);

        final categoryResponse = response.getBody(
          CategoryResponse.fromJson,
          fromKey: 'data',
        );

        return categoryResponse?.toCategoryModel();
      },
    );
  }
}
