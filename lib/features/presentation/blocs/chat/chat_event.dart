part of 'chat_bloc.dart';

sealed class ChatEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Gửi tin nhắn chat
class SendMessageSubmitted extends ChatEvent {
  final String message;

  SendMessageSubmitted(this.message);

  @override
  List<Object?> get props => [message];
}

// Gửi voice
class SendVoiceSubmitted extends ChatEvent {
  final String filePath;
  final String? message;

  SendVoiceSubmitted({
    required this.filePath,
    this.message,
  });

  @override
  List<Object?> get props => [filePath, message];
}

// Gửi bill image
class SendImageSubmitted extends ChatEvent {
  final String filePath;
  final String? message;

  SendImageSubmitted({
    required this.filePath,
    this.message,
  });

  @override
  List<Object?> get props => [filePath, message];
}
