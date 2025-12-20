import '../../data/response/category_image_response.dart';
import '../entities/category_image_model.dart';

extension CategoryImageTranslator on CategoryImageResponse {
  CategoryImageModel toCategoryImageModel() {
    return CategoryImageModel(
      publicId: publicId,
      url: url,
      thumbnail: thumbnail,
      format: format,
      bytes: bytes,
      width: width,
      height: height,
      createdAt: createdAt != null ? DateTime.tryParse(createdAt!) : null,
      folder: folder,
      filename: filename,
    );
  }
}

