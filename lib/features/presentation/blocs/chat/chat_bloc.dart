import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:finance_management_app/features/domain/entities/message_model.dart';
import 'package:finance_management_app/features/domain/repository/chat_repository.dart';
import 'package:injectable/injectable.dart';

import '../../../data/requests/chat_request.dart';

part 'chat_event.dart';
part 'chat_state.dart';

@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;

  ChatBloc(this.chatRepository) : super(ChatInitial()) {
    on<SendMessageSubmitted>(_onSendMessageSubmitted);
    on<SendVoiceSubmitted>(_onSendVoiceSubmitted);
    on<SendImageSubmitted>(_onSendImageSubmitted);
  }

  Future<void> _onSendMessageSubmitted(
    SendMessageSubmitted event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());

    final request = ChatRequest(message: event.message);

    final result = await chatRepository.chatWithGemini(request);

    result.when(
      success: (data) {
        if (data != null) {
          emit(ChatLoaded(data));
        } else {
          emit(ChatFailure('Không nhận được phản hồi từ chat'));
        }
      },
      failure: (error) {
        emit(ChatFailure(error));
      },
    );
  }

  Future<void> _onSendVoiceSubmitted(
    SendVoiceSubmitted event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());

    final result = await chatRepository.chatWithGeminiMultipart(
      message: event.message,
      voiceFilePath: event.filePath,
      billImageFilePath: null,
    );

    result.when(
      success: (data) {
        if (data != null) {
          emit(ChatLoaded(data));
        } else {
          emit(ChatFailure('Không nhận được phản hồi từ chat'));
        }
      },
      failure: (error) {
        emit(ChatFailure(error));
      },
    );
  }

  Future<void> _onSendImageSubmitted(
    SendImageSubmitted event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());

    final result = await chatRepository.chatWithGeminiMultipart(
      message: event.message,
      voiceFilePath: null,
      billImageFilePath: event.filePath,
    );

    result.when(
      success: (data) {
        if (data != null) {
          emit(ChatLoaded(data));
        } else {
          emit(ChatFailure('Không nhận được phản hồi từ chat'));
        }
      },
      failure: (error) {
        emit(ChatFailure(error));
      },
    );
  }
}
