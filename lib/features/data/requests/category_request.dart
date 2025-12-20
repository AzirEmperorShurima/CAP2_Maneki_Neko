import 'package:json_annotation/json_annotation.dart';

part 'category_request.g.dart';

@JsonSerializable()
class CategoryRequest {
  final String? name;

  final String? type;
  
  final String? image;

  CategoryRequest({
    this.name,
    this.type,
    this.image,
  });

  factory CategoryRequest.fromJson(Map<String, dynamic> json) => _$CategoryRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryRequestToJson(this);
}