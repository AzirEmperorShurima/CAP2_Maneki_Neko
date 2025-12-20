import 'package:json_annotation/json_annotation.dart';

part 'chat_request.g.dart';

@JsonSerializable()
class ChatRequest {
  final String message;

  ChatRequest({
    required this.message,
  });

  factory ChatRequest.fromJson(Map<String, dynamic> json) => _$ChatRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ChatRequestToJson(this);
}