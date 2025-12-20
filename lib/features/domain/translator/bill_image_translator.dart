import '../../data/response/bill_image_response.dart';
import '../entities/bill_image_model.dart';

extension BillImageTranslator on BillImageResponse {
  BillImageModel toBillImageModel() {
    return BillImageModel(
      url: url,
      thumbnail: thumbnail,
      publicId: publicId,
    );
  }
}
