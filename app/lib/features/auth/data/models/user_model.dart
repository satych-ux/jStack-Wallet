import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/user.dart';

part 'user_model.g.dart';

/// `{ id, name, email }`, as in login_success.json and profile.json.
@JsonSerializable(createToJson: false)
class UserModel {
  const UserModel({required this.id, required this.name, required this.email});

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  final String id;
  final String name;
  final String email;

  User toEntity() => User(id: id, name: name, email: email);
}
