import 'package:json_annotation/json_annotation.dart';

part 'google_login_request.g.dart';

@JsonSerializable()
class GoogleLoginRequest {
  final String? idToken;

  GoogleLoginRequest({
    required this.idToken,
  });

  factory GoogleLoginRequest.fromJson(Map<String, dynamic> json) =>
      _$GoogleLoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$GoogleLoginRequestToJson(this);
}

