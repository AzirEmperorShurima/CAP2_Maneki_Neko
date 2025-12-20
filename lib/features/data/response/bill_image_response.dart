import 'package:json_annotation/json_annotation.dart';

part 'bill_image_response.g.dart';

@JsonSerializable()
class BillImageResponse {
  final String? url;
  final String? thumbnail;
  final String? publicId;

  BillImageResponse({
    this.url,
    this.thumbnail,
    this.publicId,
  });

  factory BillImageResponse.fromJson(Map<String, dynamic> json) =>
      _$BillImageResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BillImageResponseToJson(this);
}
