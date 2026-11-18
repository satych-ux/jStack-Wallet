import 'package:json_annotation/json_annotation.dart';

import 'user_model.dart';

part 'login_response_model.g.dart';

/// The `data` of POST /auth/login: `{ accessToken, user }`.
@JsonSerializable(createToJson: false)
class LoginResponseModel {
  const LoginResponseModel({required this.accessToken, required this.user});

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) => _$LoginResponseModelFromJson(json);

  final String accessToken;
  final UserModel user;
}
