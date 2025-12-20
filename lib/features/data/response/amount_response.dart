import 'package:json_annotation/json_annotation.dart';

part 'amount_response.g.dart';

@JsonSerializable()
class AmountResponse {
  final num? total;

  final num? count;

  AmountResponse({
    this.total,
    this.count,
  });

  factory AmountResponse.fromJson(Map<String, dynamic> json) => _$AmountResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AmountResponseToJson(this);
}