part of 'chat_bloc.dart';

abstract class ChatState extends Equatable {
  @override
  List<Object?> get props => [];
}

final class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final MessageModel message;

  ChatLoaded(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatFailure extends ChatState {
  final String message;

  ChatFailure(this.message);

  @override
  List<Object?> get props => [message];
}
