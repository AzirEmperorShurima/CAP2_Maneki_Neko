import 'package:finance_management_app/core/network/api_result.dart';

import '../../data/requests/chat_request.dart';
import '../entities/message_model.dart';

abstract class ChatRepository {
  Future<ApiResult<MessageModel?>> chatWithGemini(ChatRequest? request);
  
  Future<ApiResult<MessageModel?>> chatWithGeminiMultipart({
    String? message,
    String? voiceFilePath,
    String? billImageFilePath,
  });
}