import 'package:json_annotation/json_annotation.dart';

import 'bill_image_model.dart';
import 'transaction_model.dart';

part 'message_model.g.dart';

@JsonSerializable()
class MessageModel {
  final TransactionModel? transaction;

  final String? jokeMessage;

  final String? message;

  final BillImageModel? billImage;

  MessageModel({
    this.transaction,
    this.jokeMessage,
    this.message,
    this.billImage,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => _$MessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$MessageModelToJson(this);
}