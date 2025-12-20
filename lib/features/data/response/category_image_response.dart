import 'package:json_annotation/json_annotation.dart';

part 'category_image_response.g.dart';

@JsonSerializable()
class CategoryImageResponse {
  final String? publicId;
  final String? url;
  final String? thumbnail;
  final String? format;
  final int? bytes;
  final int? width;
  final int? height;
  @JsonKey(name: 'createdAt')
  final String? createdAt;
  final String? folder;
  final String? filename;

  CategoryImageResponse({
    this.publicId,
    this.url,
    this.thumbnail,
    this.format,
    this.bytes,
    this.width,
    this.height,
    this.createdAt,
    this.folder,
    this.filename,
  });

  factory CategoryImageResponse.fromJson(Map<String, dynamic> json) =>
      _$CategoryImageResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryImageResponseToJson(this);
}

