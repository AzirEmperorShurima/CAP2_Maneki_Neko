import 'package:json_annotation/json_annotation.dart';

part 'bill_image_model.g.dart';

@JsonSerializable()
class BillImageModel {
  final String? url;
  final String? thumbnail;
  final String? publicId;

  BillImageModel({
    this.url,
    this.thumbnail,
    this.publicId,
  });

  factory BillImageModel.fromJson(Map<String, dynamic> json) =>
      _$BillImageModelFromJson(json);

  Map<String, dynamic> toJson() => _$BillImageModelToJson(this);
}
