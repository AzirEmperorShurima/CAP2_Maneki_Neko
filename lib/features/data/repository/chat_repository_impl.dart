import 'package:dio/dio.dart';
import 'package:finance_management_app/core/constants/endpoints.dart';
import 'package:finance_management_app/core/response/base_response.dart';
import 'package:finance_management_app/features/domain/translator/message_translator.dart';
import 'package:injectable/injectable.dart';

import '../../../core/common/bases/base_repository.dart';
import '../../../core/network/api_result.dart';
import '../../domain/entities/message_model.dart';
import '../../domain/repository/chat_repository.dart';
import '../remote/api_client.dart';
import '../requests/chat_request.dart';
import '../response/message_response.dart';

@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl extends BaseRepository implements ChatRepository {
  final ApiClient apiClient;
  final Dio dio;

  ChatRepositoryImpl(this.apiClient, this.dio);

  @override
  Future<ApiResult<MessageModel?>> chatWithGemini(ChatRequest? request) {
    return handleApiResponse<MessageModel?>(
      () async {
        final response = await apiClient.chatWithGemini(request);

        final messageResponse = response
            .getBody(MessageResponse.fromJson, fromKey: 'data')
            ?.toMessageModel();

        return messageResponse;
      },
    );
  }

  @override
  Future<ApiResult<MessageModel?>> chatWithGeminiMultipart({
    String? message,
    String? voiceFilePath,
    String? billImageFilePath,
  }) {
    return handleApiResponse<MessageModel?>(
      () async {
        final formData = FormData();

        // Thêm message nếu có
        if (message != null && message.isNotEmpty) {
          formData.fields.add(MapEntry('message', message));
        }

        // Tạo MultipartFile cho voice nếu có
        if (voiceFilePath != null && voiceFilePath.isNotEmpty) {
          final voiceFile = await MultipartFile.fromFile(
            voiceFilePath,
            filename: 'voice.${voiceFilePath.split('.').last}',
          );
          formData.files.add(MapEntry('voice', voiceFile));
        }

        // Tạo MultipartFile cho billImage nếu có
        if (billImageFilePath != null && billImageFilePath.isNotEmpty) {
          final billImageFile = await MultipartFile.fromFile(
            billImageFilePath,
            filename: 'billImage.${billImageFilePath.split('.').last}',
          );
          formData.files.add(MapEntry('billImage', billImageFile));
        }

        // Gửi request trực tiếp bằng Dio
        final response = await dio.post<Map<String, dynamic>>(
          '${ApiConfig.baseUrl}/chat/gemini',
          data: formData,
        );

        final baseResponse = BaseResponse.fromJson(response.data ?? {});
        final messageResponse = baseResponse
            .getBody(MessageResponse.fromJson, fromKey: 'data')
            ?.toMessageModel();

        return messageResponse;
      },
    );
  }
}
