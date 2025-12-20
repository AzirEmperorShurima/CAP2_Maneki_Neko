import 'package:json_annotation/json_annotation.dart';

part 'category_image_model.g.dart';

@JsonSerializable()
class CategoryImageModel {
  final String? publicId;
  final String? url;
  final String? thumbnail;
  final String? format;
  final int? bytes;
  final int? width;
  final int? height;
  final DateTime? createdAt;
  final String? folder;
  final String? filename;

  CategoryImageModel({
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

  factory CategoryImageModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryImageModelFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryImageModelToJson(this);
}
