import 'package:finance_management_app/features/data/response/message_response.dart';
import 'package:finance_management_app/features/domain/translator/bill_image_translator.dart';
import 'package:finance_management_app/features/domain/translator/transaction_translator.dart';

import '../entities/message_model.dart';

extension MessageTranslator on MessageResponse {
  MessageModel toMessageModel() {
    return MessageModel(
      transaction: transaction?.toTransactionModel(),
      jokeMessage: jokeMessage,
      message: message,
      billImage: billImage?.toBillImageModel(),
    );
  }
}