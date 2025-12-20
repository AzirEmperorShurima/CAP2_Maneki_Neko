import 'package:json_annotation/json_annotation.dart';

import 'bill_image_response.dart';
import 'transaction_response.dart';

part 'message_response.g.dart';

@JsonSerializable()

class MessageResponse {
  final TransactionResponse? transaction;

  final String? jokeMessage;

  final String? message;

  final BillImageResponse? billImage;

  MessageResponse({
    this.transaction,
    this.jokeMessage,
    this.message,
    this.billImage,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json) => _$MessageResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MessageResponseToJson(this);
}