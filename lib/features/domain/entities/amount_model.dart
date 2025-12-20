import 'package:json_annotation/json_annotation.dart';

part 'amount_model.g.dart';

@JsonSerializable()
class AmountModel {
  final num? total;

  final num? count;

  AmountModel({
    this.total,
    this.count,
  });

  factory AmountModel.fromJson(Map<String, dynamic> json) => _$AmountModelFromJson(json);

  Map<String, dynamic> toJson() => _$AmountModelToJson(this);
}